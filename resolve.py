import re

def resolve_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # We want to keep 'ours' block (from <<<<<<< ours to =======)
    # and discard 'theirs' block (from ======= to >>>>>>> theirs)
    # The markers are:
    # <<<<<<< HEAD (or ours)
    # =======
    # >>>>>>> ... (or theirs)

    # Let's write a regex to do this
    pattern = re.compile(r'<<<<<<<.*?\n(.*?)\n=======\n.*?\n>>>>>>>.*?\n', re.DOTALL)
    
    new_content = pattern.sub(r'\1\n', content)

    with open(filepath, 'w') as f:
        f.write(new_content)

resolve_file('lib/features/home/presentation/dashboard_screen.dart')
resolve_file('lib/features/buyer/presentation/products_screen.dart')
resolve_file('lib/features/orders/presentation/orders_screen.dart')

