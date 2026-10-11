import sys
import re
import os

def escape_pdf(text):
    return text.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')

def wrap_text(text, max_chars=82):
    words = text.split(' ')
    lines = []
    current_line = []
    current_len = 0
    for word in words:
        if not word:
            continue
        if current_len + len(word) + 1 <= max_chars:
            current_line.append(word)
            current_len += len(word) + 1
        else:
            if current_line:
                lines.append(' '.join(current_line))
            current_line = [word]
            current_len = len(word)
    if current_line:
        lines.append(' '.join(current_line))
    return lines

def parse_markdown_to_elements(md_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        raw_lines = f.readlines()
    
    elements = []
    for line in raw_lines:
        line_str = line.rstrip('\r\n')
        if not line_str.strip():
            elements.append(('SPACER', ''))
            continue
        
        # Heading 1
        if line_str.startswith('# '):
            elements.append(('H1', line_str[2:].strip()))
        # Heading 2
        elif line_str.startswith('## '):
            elements.append(('H2', line_str[3:].strip()))
        # Heading 3
        elif line_str.startswith('### '):
            elements.append(('H3', line_str[4:].strip()))
        # Bullet
        elif line_str.strip().startswith('- ') or line_str.strip().startswith('* ') or line_str.strip().startswith('• '):
            content = re.sub(r'^[\s\-\*\•]+\s*', '', line_str)
            elements.append(('BULLET', content.strip()))
        # Table row
        elif line_str.strip().startswith('|') and line_str.strip().endswith('|'):
            # Ignore markdown table divider
            if '---' in line_str:
                continue
            cells = [c.strip() for c in line_str.strip('|').split('|')]
            elements.append(('TABLE_ROW', cells))
        elif line_str.strip().startswith('---'):
            elements.append(('HR', ''))
        else:
            elements.append(('PARA', line_str.strip()))
            
    return elements

def build_pdf(elements, output_pdf, doc_title="Farmora Academic Report"):
    # Standard A4 size: 595.28 x 841.89 points
    # Margins: Left=50, Right=545, Top=790, Bottom=50
    page_width = 595.28
    page_height = 841.89
    margin_left = 54
    top_y = 780
    bottom_y = 54
    
    pages = []
    current_page_commands = []
    current_y = top_y
    page_num = 1
    
    def start_new_page():
        nonlocal current_page_commands, current_y, page_num
        if current_page_commands:
            # Add footer to current page
            current_page_commands.append(
                f"BT /F1 9 Tf 0.5 0.5 0.5 rg {margin_left} {bottom_y - 15} Td (SLIIT Department of Software Engineering  |  Farmora Ecosystem  |  Page {page_num}) Tj ET"
            )
            # Add footer line
            current_page_commands.append(
                f"0.8 0.8 0.8 RG 0.5 w {margin_left} {bottom_y - 5} m {page_width - margin_left} {bottom_y - 5} l S"
            )
            pages.append(list(current_page_commands))
            page_num += 1
            
        current_page_commands = []
        current_y = top_y
        
        # Add Header line and title to subsequent pages
        current_page_commands.append(
            f"0.8 0.8 0.8 RG 0.5 w {margin_left} {top_y + 15} m {page_width - margin_left} {top_y + 15} l S"
        )
        current_page_commands.append(
            f"BT /F2 8 Tf 0.4 0.4 0.4 rg {margin_left} {top_y + 20} Td ({escape_pdf(doc_title)}) Tj ET"
        )

    # Initial page
    start_new_page()
    
    for el_type, val in elements:
        if el_type == 'H1':
            if current_y < bottom_y + 70:
                start_new_page()
            current_y -= 12
            # H1 banner background
            current_page_commands.append(
                f"0.18 0.49 0.20 rg {margin_left} {current_y - 6} {page_width - margin_left*2} 24 re f"
            )
            clean_text = escape_pdf(val)
            current_page_commands.append(
                f"BT /F2 14 Tf 1 1 1 rg {margin_left + 8} {current_y} Td ({clean_text}) Tj ET"
            )
            current_y -= 26
            
        elif el_type == 'H2':
            if current_y < bottom_y + 50:
                start_new_page()
            current_y -= 10
            clean_text = escape_pdf(val)
            # Underline accent
            current_page_commands.append(
                f"0.18 0.49 0.20 RG 1.5 w {margin_left} {current_y - 3} m {margin_left + 180} {current_y - 3} l S"
            )
            current_page_commands.append(
                f"BT /F2 12 Tf 0.1 0.1 0.1 rg {margin_left} {current_y} Td ({clean_text}) Tj ET"
            )
            current_y -= 18
            
        elif el_type == 'H3':
            if current_y < bottom_y + 40:
                start_new_page()
            current_y -= 6
            clean_text = escape_pdf(val)
            current_page_commands.append(
                f"BT /F2 10.5 Tf 0.18 0.49 0.20 rg {margin_left} {current_y} Td ({clean_text}) Tj ET"
            )
            current_y -= 15
            
        elif el_type == 'HR':
            current_y -= 8
            current_page_commands.append(
                f"0.85 0.85 0.85 RG 1 w {margin_left} {current_y} m {page_width - margin_left} {current_y} l S"
            )
            current_y -= 10
            
        elif el_type == 'SPACER':
            current_y -= 8
            if current_y < bottom_y + 20:
                start_new_page()
                
        elif el_type == 'BULLET':
            wrapped = wrap_text(val, max_chars=78)
            for idx, w_line in enumerate(wrapped):
                if current_y < bottom_y + 20:
                    start_new_page()
                clean_text = escape_pdf(w_line)
                if idx == 0:
                    current_page_commands.append(
                        f"0.18 0.49 0.20 rg {margin_left + 4} {current_y + 3} 3 3 re f"
                    )
                    current_page_commands.append(
                        f"BT /F1 9.5 Tf 0.15 0.15 0.15 rg {margin_left + 14} {current_y} Td ({clean_text}) Tj ET"
                    )
                else:
                    current_page_commands.append(
                        f"BT /F1 9.5 Tf 0.15 0.15 0.15 rg {margin_left + 14} {current_y} Td ({clean_text}) Tj ET"
                    )
                current_y -= 13
                
        elif el_type == 'PARA':
            wrapped = wrap_text(val, max_chars=82)
            for w_line in wrapped:
                if current_y < bottom_y + 20:
                    start_new_page()
                clean_text = escape_pdf(w_line)
                current_page_commands.append(
                    f"BT /F1 9.5 Tf 0.2 0.2 0.2 rg {margin_left} {current_y} Td ({clean_text}) Tj ET"
                )
                current_y -= 13
                
        elif el_type == 'TABLE_ROW':
            if current_y < bottom_y + 25:
                start_new_page()
            # Draw row
            col_width = (page_width - margin_left * 2) / max(len(val), 1)
            row_height = 16
            current_page_commands.append(
                f"0.94 0.96 0.94 rg {margin_left} {current_y - 3} {page_width - margin_left*2} {row_height} re f"
            )
            current_page_commands.append(
                f"0.8 0.8 0.8 RG 0.5 w {margin_left} {current_y - 3} {page_width - margin_left*2} {row_height} re S"
            )
            for c_idx, cell in enumerate(val):
                c_clean = escape_pdf(cell[:30])
                c_x = margin_left + (c_idx * col_width) + 4
                current_page_commands.append(
                    f"BT /F2 8 Tf 0.1 0.1 0.1 rg {c_x} {current_y + 2} Td ({c_clean}) Tj ET"
                )
            current_y -= (row_height + 4)

    # Flush final page
    if current_page_commands:
        current_page_commands.append(
            f"BT /F1 9 Tf 0.5 0.5 0.5 rg {margin_left} {bottom_y - 15} Td (SLIIT Department of Software Engineering  |  Farmora Ecosystem  |  Page {page_num}) Tj ET"
        )
        current_page_commands.append(
            f"0.8 0.8 0.8 RG 0.5 w {margin_left} {bottom_y - 5} m {page_width - margin_left} {bottom_y - 5} l S"
        )
        pages.append(list(current_page_commands))

    # --- Low-level PDF Assembly ---
    num_pages = len(pages)
    objects = []
    
    def add_obj(body):
        objects.append(body)
        return len(objects)

    # Obj 1: Catalog
    add_obj("<< /Type /Catalog /Pages 2 0 R >>")
    # Obj 2: Pages placeholder
    add_obj("") 
    # Obj 3: Font F1 (Helvetica)
    add_obj("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    # Obj 4: Font F2 (Helvetica-Bold)
    add_obj("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")

    page_obj_ids = []
    
    for p_cmds in pages:
        stream_content = "\n".join(p_cmds)
        stream_len = len(stream_content.encode('latin1', 'replace'))
        content_obj = add_obj(f"<< /Length {stream_len} >>\nstream\n{stream_content}\nendstream")
        page_obj = add_obj(
            f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {page_width} {page_height}] "
            f"/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> "
            f"/Contents {content_obj} 0 R >>"
        )
        page_obj_ids.append(page_obj)

    # Update Pages object (Obj 2)
    kids_str = " ".join([f"{pid} 0 R" for pid in page_obj_ids])
    objects[1] = f"<< /Type /Pages /Kids [{kids_str}] /Count {num_pages} >>"

    # Write PDF stream
    pdf_bytes = bytearray()
    pdf_bytes.extend(b"%PDF-1.4\n")
    
    xref_offsets = []
    for idx, obj_body in enumerate(objects):
        offset = len(pdf_bytes)
        xref_offsets.append(offset)
        pdf_bytes.extend(f"{idx+1} 0 obj\n{obj_body}\nendobj\n".encode('latin1', 'replace'))
        
    startxref = len(pdf_bytes)
    pdf_bytes.extend(b"xref\n")
    pdf_bytes.extend(f"0 {len(objects)+1}\n".encode('latin1'))
    pdf_bytes.extend(b"0000000000 65535 f \n")
    for off in xref_offsets:
        pdf_bytes.extend(f"{off:010d} 00000 n \n".encode('latin1'))
        
    pdf_bytes.extend(f"trailer\n<< /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{startxref}\n%%EOF\n".encode('latin1'))
    
    with open(output_pdf, 'wb') as f:
        f.write(pdf_bytes)
    print(f"Generated {output_pdf} successfully with {num_pages} pages.")

def main():
    base_dir = "/Users/ahsan/Documents/Farmora-app/Farmora-App/docs/academic_submission"
    
    reports = [
        (os.path.join(base_dir, "milestone_01/MILESTONE_1_REPORT.md"),
         os.path.join(base_dir, "milestone_01/Farmora_Milestone_01_Report.pdf"),
         "Farmora - Milestone 1: UX Team, User Research & Key Flows"),
         
        (os.path.join(base_dir, "milestone_02/MILESTONE_2_REPORT.md"),
         os.path.join(base_dir, "milestone_02/Farmora_Milestone_02_Report.pdf"),
         "Farmora - Milestone 2: Prototyping & Design System"),
         
        (os.path.join(base_dir, "milestone_03/MILESTONE_3_REPORT.md"),
         os.path.join(base_dir, "milestone_03/Farmora_Milestone_03_Report.pdf"),
         "Farmora - Milestone 3: User Testing & Security Iterations"),
         
        (os.path.join(base_dir, "milestone_04/MILESTONE_4_REPORT.md"),
         os.path.join(base_dir, "milestone_04/Farmora_Milestone_04_Report.pdf"),
         "Farmora - Milestone 4: Tech Stack Justification & App Implementation"),
         
        (os.path.join(base_dir, "milestone_05/MILESTONE_5_REPORT.md"),
         os.path.join(base_dir, "milestone_05/Farmora_Milestone_05_Report.pdf"),
         "Farmora - Milestone 5: Promotion, GTM Strategy & Business Pitching"),
         
        (os.path.join(base_dir, "milestone_05/FARMORA_PITCH_DECK.md"),
         os.path.join(base_dir, "milestone_05/Farmora_Milestone_05_Pitch_Deck.pdf"),
         "Farmora - Investor & Academic Pitch Deck"),
         
        (os.path.join(base_dir, "milestone_05/VIDEO_SCRIPTS_AND_PROMOTION.md"),
         os.path.join(base_dir, "milestone_05/Farmora_Milestone_05_Promotional_Material.pdf"),
         "Farmora - Video Demonstration & A3 Poster Specifications"),
         
        (os.path.join(base_dir, "milestone_06/MILESTONE_6_REPORT.md"),
         os.path.join(base_dir, "milestone_06/Farmora_Milestone_06_Report.pdf"),
         "Farmora - Milestone 6: Individual Contribution & VIVA Prep"),
    ]
    
    # Also compile a Master Comprehensive Report (M1-M6)
    combined_elements = []
    combined_elements.append(('H1', 'Farmora - Comprehensive Academic Report (Milestones 1 to 6)'))
    combined_elements.append(('PARA', 'Department of Software Engineering, Faculty of Computing'))
    combined_elements.append(('PARA', 'Sri Lanka Institute of Information Technology (SLIIT)'))
    combined_elements.append(('PARA', 'Mobile Application Project - Complete Academic Dossier'))
    combined_elements.append(('HR', ''))
    
    for in_md, out_pdf, title in reports:
        if os.path.exists(in_md):
            elems = parse_markdown_to_elements(in_md)
            build_pdf(elems, out_pdf, title)
            combined_elements.extend(elems)
            combined_elements.append(('HR', ''))
            
    master_pdf = os.path.join(base_dir, "Farmora_Complete_Project_Report_Milestones_1_to_6.pdf")
    build_pdf(combined_elements, master_pdf, "Farmora: Comprehensive Project Report (M1 - M6)")

if __name__ == "__main__":
    main()
