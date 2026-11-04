; © Realix > Disk: Write
; (04.11.26) v0.1
; ================
; ❗️ Зависимости: bios-api/disk/read (lba_to_chs, disk_reset - внешние)

; ❗️ Требуется инициализация диска через `bios_disk_init`
;    и включение bios-api/disk/read.asm (lba_to_chs, disk_reset)
%include "bios-api/disk/read.asm"

; Защита от повторного включения
%ifndef BIOS_DISK_WRITE
%define BIOS_DISK_WRITE


; > Запись секторов на диск
; ❗️ Номер диска берётся из `bios-api/disk/init/curr_drive_num`
;    При неудачном завершении НЕ вызывает error_handler (решает вызывающий)
; Параметры:
;  - ax: LBA
;  - cl: кол-во секторов для записи (до 128)
;  - es:bx: адрес источника данных
; Вывод:
;  - CF (Carry Flag): 0 (Успех), 1 (Ошибка)
;  - si: смещение адреса сообщения об ошибке (0 - успех)
bios_disk_write:
    push ax
    push cx
    push dx
    push di

    ; Получаем номер текущего диска
    mov dl, [curr_drive_num]

    push cx          ; *Сохраняем кол-во секторов (cl)
    call lba_to_chs
    pop ax           ; *Восстанавливаем кол-во секторов (cl -> al)

    mov ah, 03h      ; Функция BIOS: Запись секторов
    mov di, 3        ; Кол-во попыток записи

.retry:
    pusha     ; Сохранение регистров (BIOS может их испортить)
    stc       ; Установка Carry Flag (Некоторые BIOS не устанавливают)
    int 0x13
    jnc .done

    ; Если "Ошибка", сбрасываем контроллер диска
    popa
    call disk_reset

    ; Переход к след. попытке
    dec di
    jnz .retry

.fail:
    ; Все попытки исчерпаны
    pop di
    pop dx
    pop cx
    pop ax

    stc
    mov si, err_write_failed
    ret

.done:
    popa

    pop di
    pop dx
    pop cx
    pop ax

    clc
    xor si, si
    ret


; Сообщения об ошибках
err_write_failed: db '[!] E11: Disk write failed!', 0

%endif
