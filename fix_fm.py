import sys
p = r'd:\game-dev\homasim-godot\autoload\FinanceManager.gd'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('func add_transaction(amount: int, category: String, description: String) -> void:', 'func add_transaction(amount: int, category: String, description: String, log_it: bool = true) -> void:')
c = c.replace('if ActivityLog:\n    var sign_str = "+" if amount > 0 else ""', 'if ActivityLog and log_it:\n    var sign_str = "+" if amount > 0 else ""')
with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
