import urllib.request
import os

base_dir = r"c:\Users\Gowsikan Sivananthan\Desktop\Farmora-app\stitch_export"
img_dir = os.path.join(base_dir, "images")
html_dir = os.path.join(base_dir, "html")

items = [
    # (url, filepath)
    ("https://lh3.googleusercontent.com/aida/AP1WRLt5xJh9YHioSXvjJYQndELTixcgTA12ZGMULEO3to3bZ2qlKJCk4VOCaesjlmTIl9maBv3B0i8V41vbJPENRYVl7InULvlP8Xw2DX_Uf1UomppeoT_QczYHHTX7JdylroyyuE0YlQq-cUwkSZF5pfjuiGDElHnFSJ8BwFVLCQC_kGDTSqns9xFs46IpnMVCzER11-AaCDZMh0tehO4wlKOUqRLyivF93EFKOlq4dUQdE3hOy-8KQPjsPiY", os.path.join(img_dir, "farmora_logo.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLtTcbwhof-1eRjAFToKitQtT28majNeKhB7hPHxexpF8ESzPNdndEUt9fATM4U722EeV56C-ybp5zRH6yTP1BocQ73MTyokoUfvixm6pVdlTHZZnA090hrUD7kudzP63GZ0D9wcUlo7lz8_w5eIyJzGl0BZejwnFcizO8UODW_7JwJAW733cA_KU75x6bBZuvcGXoAxIGkArjSHr1XCmaVqAxLOJYpCPMdQsbhFKibApyzBSyLAl7C-zS0", os.path.join(img_dir, "farmer_headshot.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLvzUFamtUq6PNFalsGNhy8ZvUoRm5urvCh11J3SOgdLuqOT8uyUK1IT_M5nNKufQPTxaQS2sVjBlLkyDzhNfkQju5PBRn8_jWjJVqMurQJApyEXJM1ql37CrrHwdM2Neq1bmYDfGKiHhJkKIlDl9e9nzx5S5nS6rEvI1XB4bn_PVTtgJmYZsZzuDIezuo6TEyMxCVr2u5PkKVmkbpBA0yZcqY1WgfoyRALVgodrB7ajXr0nvxBxHF8kSg", os.path.join(img_dir, "add_product.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLtPdGDjSEbCz9VoSq9G0WCV9AJUHrPN00icnOhcGMbxmYMVPDrtJ9AyEMuNf7H3nh4v5dp1wuA8v3R0tHcuxtRI4OFxfHvuRq2cbAnKGKURTKqzIn90Ob4AVJzzlBGzLIUp7b66JrF_SoBFKUeftlpGeey9ATLrfmNiEMS8uQPwJnY_fDl57xgY_05CavcpcIRwwklIOZK_tcmlQ8Z48BfN7cdiiTr8QPkkp8fJ3Vet7b9EtvEPdRTYEnM", os.path.join(img_dir, "incoming_orders.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLsPLleuQJ2ivvxG1Diw4XQ-rdW0QyqWiprE638DYdMQGWUgW-BBDzaNi4t5V8zLi0rLzonhYImG0nZwfePYbX5e296rJqxz7nNgZ18WdUMpgJBDMibDnTf4J1LmriGocttiIGymBZObBEX47oPk7uaMnj_bs5vv7gSz3OavpBJIMjcNboatWibQiw245uQE6sdpY83RPCx6LG6YHKF7KnIcBmpB5YmtylZKQi5Ivko-RND9AEKI9AhjKw", os.path.join(img_dir, "my_products.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLvRphBNeq-GBnwjCfx6RCcYDHZEMBj8C_efxPzm0QiiUgD_CSXd7_lzk_zjQ67xqEjJxQ_SGEuWAXzd-WVUi5BfqcwTVQQGpuf4w4dJA0IPyOxOZJfkJpbTNcQIUNZf-tD-O8hzKer3CDVTyVqATzipISj9t_LlcgVEXE5etAk-ccd6O8wiYcZUU1zERAgJrv3SBicGhmWDmUxXQxIy7Ma6E-1ynqa0en1OrWAB6plMOb-Lnu_UOga2MH0", os.path.join(img_dir, "earnings_dashboard.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLvFrrrP34fFW8RCcft_NwOQjQI1oNZ81QTVMm-L6B9U8bT3twsnfjF5X8IFdCqlj906aP4_VTozj1NiBqzKnkDVBF4falITDLeI5Ez1KS3Z7ufWzA3hQWFA9OibATMDuZ9p5Rx5ipK6A6U6cidLU5nia2CHbi0-5PWfq0WxYqN46TUNElzcxuv-iqKUJE6OaBiG6lH6CYCP_IuXJJBFF71YQirMuhwDzbjMffrF57IALV42Jvd_WBZSsA", os.path.join(img_dir, "order_detail.png")),
    ("https://lh3.googleusercontent.com/aida/AP1WRLvXNub6P9hKRjR9ej9MP4NTipX342FQ7kff5VkLVq63CZ8CNcz8Y1fLbjLCy7aa7kXt8UxmByDLb9AIjOug4AOcqEiBQ6KQxvMORlQeDpl5d63aTkpVDy3fFdhx9CkXvTBXati3iul1nkrjTpW-0lX9E2qRiZ_O2IhLEL1hWS6UJIKHQ0aPvPCpAbYiz63c93C8OwRj8fKAHb-fUf8SVn54aJYFTAuo4EamMSrli3ahLHEyGuvv530W6Lc", os.path.join(img_dir, "account_verification.png")),
    
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWY0OGNmOGQwNzNhZjNlYmVkMjdhNjEzEgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "add_product.html")),
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWYxN2M5ZGYwNTIyYTM2NDhhMjBlMDg3EgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "incoming_orders.html")),
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWY4MDU3MDIwMmQzZmVmMjczMWYwMGRiEgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "my_products.html")),
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWY1MzBmMTAwMWI0ZTc2NzdlMTI3NGM5EgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "earnings_dashboard.html")),
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWYzOThkYjYwMWE2MGU0YTcyMDQxMTg0EgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "order_detail.html")),
    ("https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ7Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpaCiVodG1sXzAwMDY1OThlZWVlZTFmMjAwOTI1ZDU5YmFlMDc2Mjc2EgsSBxCV9KSr3hkYAZIBIwoKcHJvamVjdF9pZBIVQhM2NTUwNjMxNjM0OTY5MjAxNDc4&filename=&opi=89354086", os.path.join(html_dir, "account_verification.html")),
]

req_headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

for url, target_path in items:
    print(f"Downloading {os.path.basename(target_path)}...")
    req = urllib.request.Request(url, headers=req_headers)
    with urllib.request.urlopen(req) as resp, open(target_path, "wb") as f:
        f.write(resp.read())
    print(f"Saved: {target_path} ({os.path.getsize(target_path)} bytes)")

print("All downloads finished successfully!")
