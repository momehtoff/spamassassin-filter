#####################################################################################################
### Decode UTF-8 2 Russian symbols for Text filter 4 SpamAssassin                                 ###
### v.20230929                                                                                    ###
#####################################################################################################

Param (
	[string] $inputFilter = $(Read-Host -prompt "Введите значение inputFilter")

)

$fileUTF8Rus = 'decode.tbl';

if (-not $inputFilter) {
	Write-Warning "Не введено значение параметра [inputFilter]!";
	exit;
}

Write-Host "Длина входящей строки:" $inputFilter.Length "символов";

$current_dir = ($MyInvocation.MyCommand.Path | split-path -parent); # Текущий каталог

$check_UTF8Rus = (Test-Path -Path ($current_dir + '\' + $fileUTF8Rus));

if (-not $check_UTF8Rus) {
	Write-Warning "Файл [$fileUTF8Rus] не найден!"
	exit;
}

# Повторный подсчет открытых и закрытых скобок на несоответствие
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

# Конвертация UTF8 кодировки в русские буквы
$utf8_table = (Get-Content -Path ($current_dir + '\' + $fileUTF8Rus));

$resultFilter = $inputFilter;

foreach ($str in $utf8_table) {
    $template_arr = $str.Split(':');
    $rus_letters = $template_arr[1].Split('|');

    #Write-Host $template_arr[0];
    #Write-Host $rus_letters[0];
    #Write-Host $rus_letters[1];

    while ($resultFilter.Contains($template_arr[0])) {
        $resultFilter = $resultFilter.Replace($template_arr[0], $rus_letters[0]);
    }
}

# Удаление ([[:blank:][:punct:]]?)
$resultFilter_clean = $resultFilter;

while ($resultFilter_clean.Contains('([[:blank:][:punct:]]?)')) {
    $resultFilter_clean = $resultFilter_clean.Replace('([[:blank:][:punct:]]?)', '');
}

# Повторный подсчет открытых и закрытых скобок на несоответствие
$count_open_round_brackets = 0;
$count_close_round_brackets = 0;

for ($idx = 0; $idx -lt $resultFilter.Length; $idx++) {
    if ($resultFilter[$idx] -eq '(') { $count_open_round_brackets++; }
    if ($resultFilter[$idx] -eq ')') { $count_close_round_brackets++; }
}

if ($count_open_round_brackets -ne $count_close_round_brackets) {
    Write-Warning "Количество открывающихся круглых скобок не равно количеству закрывающихся скобок!"
    Write-Host "Количество открывающихся круглых скобок:" $count_open_round_brackets;
    Write-Host "Количество закрывающихся круглых скобок:" $count_close_round_brackets;
}

# Пробуем разделить фильтры
$resultFilter_arr = @();

$count_open_round_brackets = 0;
$count_close_round_brackets = 0;
$begin_cut = 0;

for ($idx = 0; $idx -lt $resultFilter.Length; $idx++) {
    if ($resultFilter[$idx] -eq '(') { $count_open_round_brackets++; }
    if ($resultFilter[$idx] -eq ')') { $count_close_round_brackets++; }

    if ($count_open_round_brackets -gt 0 -and $count_close_round_brackets -gt 0) {
        if ($count_open_round_brackets -eq $count_close_round_brackets) {
            if ($idx -lt $resultFilter.Length) {
                if ($resultFilter[$idx] -eq '|') {
                    $resultFilter_arr += $resultFilter.Substring($begin_cut, $idx - $begin_cut);
                    $begin_cut = $idx + 1;
                }
            }
        }
    }
    
    if (($idx + 1) -eq $resultFilter.Length) {
        $resultFilter_arr += $resultFilter.Substring($begin_cut, $resultFilter.Length - $begin_cut);
    }
}

# Вывод результата
Write-Host "Длина строки на выходе:" $resultFilter.Length "символов";
Write-Host "----- Результат #1 -----";
Write-Host $resultFilter;
Write-Host "----- Результат #2 -----";
Write-Host $resultFilter_clean;
Write-Host "----- Результат #3 -----";

for ($filter_idx = 0; $filter_idx -lt $resultFilter_arr.Count; $filter_idx++) {
    $index = $filter_idx + 1;
    Write-Host '>>>' $index ':'  $resultFilter_arr[$filter_idx];
}
