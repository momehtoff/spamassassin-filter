#####################################################################################################
### Convertor Russian symbols 2 UTF-8 for Text filter 4 SpamAssassin                              ###
### v.20231003                                                                                    ###
#####################################################################################################

Param (
	[string] $inputFilter = $(Read-Host -prompt "Введите значение inputFilter"),
    [switch] $addBP,                                                               # Добавить ([[:blank:][:punct:]]?) после каждого символа
    [switch] $codeRus2UTF8                                                         # Русские буквы кодировать в таблицу символов UTF8
)

$letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя";
$no_PB_letters      = ".?|)";
$file_convert_table = 'convert.tbl';
$file_codesRus2UTF8 = 'Rus2UTF8.tbl';

if ($codeRus2UTF8) { $file_convert_table = $file_codesRus2UTF8; }   # Кодировать по таблице UTF8

if (-not $inputFilter) {
	Write-Warning "Не введено значение параметра [inputFilter]!";
	exit;
}

Write-Host "Длина входящей строки:" $inputFilter.Length "символов";

$current_dir = ($MyInvocation.MyCommand.Path | split-path -parent); # Текущий каталог

$check_RusUTF8 = (Test-Path -Path ($current_dir + '\' + $file_convert_table));

if (-not $check_RusUTF8) {
	Write-Warning "Файл [$file_convert_table] не найден!"
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

# Добавление ([[:blank:][:punct:]]?)
#if ($addBP) {
#    $PBFilter = "";
#
#    for ($idx = 0; $idx -lt $inputFilter.Length; $idx++) {
#        $PBFilter += $inputFilter[$idx];
#
#        if ($letters.Contains($inputFilter[$idx])) {    # Добавляем BP после букв
#            if (($idx + 1) -lt $inputFilter.Length) {
#                if (-not $no_PB_letters.Contains($inputFilter[$idx + 1])) {
#                    $PBFilter += '([[:blank:][:punct:]]?)';
#                }
#            }
#        }
#
#        if ($inputFilter[$idx] -eq ')') {                       # Добавляем BP после круглой скобки, перед буквами
#            if (($idx + 1) -lt $inputFilter.Length) {
#                if ($letters.Contains($inputFilter[$idx + 1])) {
#                    $PBFilter += '([[:blank:][:punct:]]?)';
#                }
#            }
#        }
#    }
#
#    if ($PBFilter.Length -gt 0) { $inputFilter = $PBFilter; }
#}

# Конвертация букв
$convert_table = (Get-Content -Path ($current_dir + '\' + $file_convert_table));

$resultFilter = "";

for ($idx = 0; $idx -lt $inputFilter.Length; $idx++) {
    if ($letters.Contains($inputFilter[$idx])) {
        $replacement_found = $false;

        foreach ($str in $convert_table) {
            if ($str.Contains($inputFilter[$idx])) {
                $str_arr = $str.Split(':');

                $resultFilter += $str_arr[1];
                $replacement_found = $true;
                break;
            }
        }
        
        if (-not $replacement_found) {  # Замена не найдена
            $resultFilter += $inputFilter[$idx];
            Write-Warning "Не найдена замена для символа" $inputFilter[$idx];
        }

        if ($addBP) {   # Добавление ([[:blank:][:punct:]]?)
            if (($idx + 1) -lt $inputFilter.Length) {
                if (-not $no_PB_letters.Contains($inputFilter[$idx + 1])) { $resultFilter += '([[:blank:][:punct:]]?)'; }
            }
        }
    } else {
        $resultFilter += $inputFilter[$idx];

        if ($addBP) {   # Добавление ([[:blank:][:punct:]]?)
            if ($inputFilter[$idx] -eq ')') {                       # Добавляем BP после круглой скобки, перед буквами
                if (($idx -gt 0) -and (($idx + 1) -lt $inputFilter.Length)) {
                    if ($letters.Contains($inputFilter[$idx + 1]) -or $inputFilter[$idx + 1] -eq '(') { $resultFilter += '([[:blank:][:punct:]]?)'; }
                }
            }
        }
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
