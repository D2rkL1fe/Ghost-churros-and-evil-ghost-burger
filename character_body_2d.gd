extends CharacterBody2D

# Основни свойства на Чуроса
var churro_name: String = "Чурос"
var heal_amount: int = 10        # колко живот връща
var value: int = 1               # колко точки носи
var is_collected: bool = false   # дали вече е взет

# Декоративни свойства
var rotation_speed: float = 60.0 # въртене за ефект
var float_height: float = 5.0    # височина на поклащане
var float_speed: float = 2.0     # колко бързо се поклаща
