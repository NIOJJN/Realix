; © Realix > Command: Write
; © copyright by vv1ra
; (04.11.26) v0.1
; ================
; ❗️ Зависимости: filesystem/fat12/file_write.asm (fat12_write),
;                 kernel16: io print, print_reg, shell utils (skip_spaces),
;                 format_83 (из kernel16/commands/filesystem/load.asm)

; Лимит буфера текста файла (Shell входной буфер: 64 символа)
WRITE_DATA_BUFFER_LEN equ 128

; > Команда записи текста в файл на диск: write <имя файла> <текст>
; (Создает файл или перезаписывает существующий)
; Параметры:
;  - si: указатель на аргументы (после имени команды)
cmd_write:
    push ax
    push cx
    push si
    push di

    ; Разбор имени файла (si -> за именем)
    call skip_spaces
    cmp byte [si], 0
    jne .parse_name
    jmp .usage

.parse_name:
    call format_83
    jnc .text_ready
    jmp .usage

.text_ready:
    ; Пропуск пробелов до текста файла
    call skip_spaces

    ; Копирование текста в буфер команды (С подсчётом размера)
    mov di, write_data_buffer
    mov cx, WRITE_DATA_BUFFER_LEN
.copy_loop:
    ; Счётчик может исчерпаться раньше конца строки - обрезаем текст
    jcxz .copy_done

    ; Загрузка символа текста
    lodsb
    test al, al
    jz .copy_done

    ; Сохранение символа в буфер
    mov [di], al
    inc di
    dec cx
    jmp .copy_loop

.copy_done:
    ; Вычисление размера текста: di - начало буфера
    mov ax, di
    sub ax, write_data_buffer
    mov [write_size], ax

    ; Сохранение файла (Сегменты fat12_write настроит сам)
    ; > si: имя (8.3), ax: размер, cx:bx: источник данных
    mov cx, ds
    mov bx, write_data_buffer
    mov si, filename_83
    call fat12_write
    jc .fail

    ; Логирование успеха с фактическим размером файла
    mov si, msg_write_ok
    call print
    mov ax, [write_size]
    call print_dec16
    mov si, str_write_bytes
    call print
    jmp .done

; Вывод сообщения (usage при пустом имени / ошибка fat12_write - si)
.usage:
    mov si, msg_write_usage

.fail:
    call print

.done:
    pop di
    pop si
    pop cx
    pop ax

    ret

; Переменные модуля
write_size:         dw 0

; Буфер текста файла
write_data_buffer:  times WRITE_DATA_BUFFER_LEN db 0

; Сообщения
msg_write_usage: db '[?] Usage: write <filename> <text>', 0
msg_write_ok:    db '[+] File saved, ', 0
str_write_bytes: db ' bytes', 0
