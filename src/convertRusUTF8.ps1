#####################################################################################################
### Convertor Russian symbols 2 UTF-8 for Text filter 4 SpamAssassin                              ###
### v.20230921                                                                                    ###
#####################################################################################################

Param (
	[string] $inputFilter = $(Read-Host -prompt "Введите значение inputFilter")
)

$russian_letters = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя";

if (-not $inputFilter) {
	Write-Warning "Не введено значение параметра [inputFilter]!";
	exit;
}

Write-Host "Длина входящей строки:" $inputFilter.Length "символов";

$current_dir = ($MyInvocation.MyCommand.Path | split-path -parent); # Текущий каталог

$check_RusUTF8 = (Test-Path -Path ($current_dir + '\RusUTF8.txt'));

if (-not $check_RusUTF8) {
	Write-Warning "Файл [RusUTF8.txt] не найден!"
	exit;
}

# Подсчет открытых и закрытых скобок
$count_open_round_brackets = 0;
$count_close_round_brackets = 0;

for ($idx = 0; $idx -lt $inputFilter.Length; $idx++) {
    if ($inputFilter[$idx] -eq '(') { $count_open_round_brackets++; }
    if ($inputFilter[$idx] -eq ')') { $count_close_round_brackets++; }
}

if ($count_open_round_brackets -ne $count_close_round_brackets) {
    Write-Warning "Количество открывающихся круглых скобок не равно количеству закрывающихся скобок!"
    Write-Host "Количество открывающихся круглых скобок:" $count_open_round_brackets;
    Write-Host "Количество закрывающихся круглых скобок:" $count_close_round_brackets;
	exit;
}

# Конвертация русских букв в UTF8 кодировку
$utf8_table = (Get-Content -Path ($current_dir + '\RusUTF8.txt'));

$resultFilter = "";

for ($idx = 0; $idx -lt $inputFilter.Length; $idx++) {
    if ($russian_letters.Contains($inputFilter[$idx])) {
        foreach ($str in $utf8_table) {
            if ($str.Contains($inputFilter[$idx])) {
                $str_arr = $str.Split(':');

                $resultFilter = $resultFilter + $str_arr[1];
                break;
            }
        }
    } else {
        $resultFilter = $resultFilter + $inputFilter[$idx];
    }
}

# Повторный подсчет открытых и закрытых скобок
$count_open_round_brackets = 0;
$count_close_round_brackets = 0;

for ($idx = 0; $idx -lt $inputFilter.Length; $idx++) {
    if ($inputFilter[$idx] -eq '(') { $count_open_round_brackets++; }
    if ($inputFilter[$idx] -eq ')') { $count_close_round_brackets++; }
}

if ($count_open_round_brackets -ne $count_close_round_brackets) {
    Write-Warning "Количество открывающихся круглых скобок не равно количеству закрывающихся скобок!"
    Write-Host "Количество открывающихся круглых скобок:" $count_open_round_brackets;
    Write-Host "Количество закрывающихся круглых скобок:" $count_close_round_brackets;
}

# Вывод результата
Write-Host "Длина строки на выходе:" $resultFilter.Length "символов";
Write-Host $resultFilter;
