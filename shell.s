.text
#############################
# comentar para rodar na DE1, descomentar para rodar no rars
.include "MACROSv26.s"
j shell.clear_cmd
m_final
#############################
.include "SYSTEMv26.s"

.data
.eqv PROMPT 0x3E
.eqv TERM_COLOR 0x00FF
.align 2
buffer:     .space 40   # buffer para comando do usuario
curr_line:  .byte 0     # linha atual na tela
no_cmd_error:       .string "Erro: comando nao existe"
no_bin_file_error:  .string "Erro: arquivo .bin nao encontrado"
no_dat_file_error:  .string "Erro: arquivo .dat nao encontrado"
text_size_error:    .string "Erro: secao de codigo maior que 64 KiB"
data_size_error:    .string "Erro: secao de dados maior que 128 KiB"
help_msg1:          .string "Comandos:"
help_msg2:          .string "Tamanho maximo de um cmd eh 40 chars"
help_msg3:          .string "Para exec:"
help_msg4:          .string "  .text deve estar em programa.bin"
help_msg5:          .string "  .data deve estar em programa.dat"

### Comandos ###
echo_str:   .string "echo"
clear_str:  .string "clear"
exit_str:   .string "exit"
exec_str:   .string "exec"
help_str:   .string "help"

.text
shell.read: li a0, PROMPT
    li a1, 0
    la t0, curr_line
    lbu a2, 0(t0)
    slli a2, a2, 4
    li a3, TERM_COLOR
    li a4, 0
    li a7, 111
    ecall   # imprime o prompt na tela

    la a0, buffer
    li a1, 39
    li a2, 8
    la t0, curr_line
    lbu a3, 0(t0)
    slli a3, a3, 4
    li a4, TERM_COLOR
    li a5, 0
    li a7, 81
    ecall   # read string interativo
    mv s2, a1

    la a0, buffer
    la a1, echo_str
    jal starts_with
    bnez a0, shell.echo_cmd

    la a0, buffer
    la a1, exec_str
    jal starts_with
    bnez a0, shell.exec_cmd

    la a0, buffer
    la a1, clear_str
    jal starts_with
    bnez a0, shell.clear_cmd

    la a0, buffer
    la a1, exit_str
    jal starts_with
    bnez a0, shell.exit_cmd

    la a0, buffer
    la a1, help_str
    jal starts_with
    bnez a0, shell.help_cmd

# comando nao implementado
    la a0, no_cmd_error
    jal shell.print_line
    jal shell.inc_line
#    la t0, curr_line
#    lbu t1, 0(t0)
#    addi t1, t1, 1
#    sb t1, 0(t0)
    j shell.reset_buffer

shell.help_cmd: la a0, help_msg1
    jal shell.print_line
    la a0, echo_str
    jal shell.print_line
    la a0, clear_str
    jal shell.print_line
    la a0, exec_str
    jal shell.print_line
    la a0, exit_str
    jal shell.print_line
    la a0, help_str
    jal shell.print_line
    la a0, help_msg2
#    jal shell.print_line
    la a0, help_msg3
    jal shell.print_line
    la a0, help_msg4
    jal shell.print_line
    la a0, help_msg5
    jal shell.print_line
    jal shell.inc_line
#    la t0, curr_line
#    lbu t1, 0(t0)
#    addi t1, t1, 1
#    sb t1, 0(t0)
    j shell.reset_buffer

shell.clear_cmd: la t0, curr_line
    sb zero, 0(t0)
    li a0, 0
    li a1, 0
    li a7, 148
    ecall
    j shell.reset_buffer

shell.echo_cmd: la t0, buffer
    addi a0, t0, 5    # como eh echo, pula "echo "
    jal shell.print_line
    jal shell.inc_line
#    la t0, curr_line
#    lbu t1, 0(t0)
#    addi t1, t1, 1
#    sb t1, 0(t0)
    j shell.reset_buffer

shell.exec_cmd: la t0, buffer
    addi a0, t0, 5    # como eh exec, pula "exec "
    j loader

shell.exit_cmd: j shell.exit_cmd

shell.reset_buffer:
    la t0, buffer
    li t1, 10
reset_buffer.loop: sw zero, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, reset_buffer.loop
    j shell.read

shell.inc_line: addi sp, sp, -4
    sw ra, 0(sp)
    la t0, curr_line
    lbu t1, 0(t0)
    li t2, 14
    blt t1, t2, inc_line.no_scroll
    jal shell.scroll
    j inc_line.end
inc_line.no_scroll: addi t1, t1, 1
    sb t1, 0(t0)
inc_line.end: lw ra, 0(sp)
    addi sp, sp, 4
    ret

# so funciona com o prompt em linhas pares (indexadas em 0)
# nao existe situacao no momento em que isso pode acontecer
# consertar?
shell.scroll: li t4, VGAADDRESSINI0
    li t5, 320
    slli t5, t5, 5  # 32 linhas de pixels -> duas linhas no terminal
    add t5, t5, t4  # t5 = frame 0 + offset 
    li t6, VGAADDRESSFIM0
scroll.loop: bge t5, t6, scroll.cleanup
    lw t3, 0(t5)
    sw t3, 0(t4)
    addi t4, t4, 4
    addi t5, t5, 4
    j scroll.loop
scroll.cleanup: bge t4, t6, scroll.end
    sw zero, 0(t4)
    addi t4, t4, 4
    j scroll.cleanup
scroll.end: la t4, curr_line
    li t2, 12
    sb t2, 0(t4)
    ret

# print_line
# a0 = string
shell.print_line: addi sp, sp, -4
    sw ra, 0(sp)
    li a1, 0
    la t1, curr_line
    lbu t2, 0(t1)
    li t3, 14     # ultima linha da tela
    blt t2, t3, printline.end
    jal shell.scroll
printline.end: addi a2, t2, 1 # incrementa linha
    addi t2, t2, 1  # proxima linha 
    sb t2, 0(t1)
    slli a2, a2, 4  # offset da linha
    li a3, TERM_COLOR
    li a4, 0
    li a7, 104
    ecall
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# starts_with
# a0 = string
# a1 = prefixo
##############
# retorna
# a0 = a0 comeca com a1
starts_with: lbu t1, 0(a1) # char do prefixo
    lbu t0, 0(a0)         # char da string
    beqz t1, starts_with.preEnd  # se prefixo acabou
    bne t0, t1, starts_with.false  # se char eh diferente do prefixo
    addi a0, a0, 1  # incrementa ponteiro da string
    addi a1, a1, 1  # incrementa ponteiro do prefixo
    j starts_with

starts_with.preEnd: li t1, 0x20  
    beq t0, t1, starts_with.true # checa se proximo char eh espaco
    beqz t0, starts_with.true    # checa se proximo char eh nulo

starts_with.false: li a0, 0
    j starts_with.end

starts_with.true: li a0, 1

starts_with.end: ret

# fileSize
# a0 = descritor do arquivo
# retorna
# a0 = tamanho do arquivo
fileSize: mv t0, a0
    li a1, 0
    li a2, 2
    li a7, 62
    ecall
    mv t1, a0
    
    mv a0, t0
    li a1, 0
    li a2, 0
    li a7, 62
    ecall
    mv a0, t1
    ret

loader: li a1, 0
    li a7, 1024
    ecall   # abre o arquivo de codigo
    bltz a0, loader.no_bin_file_err
    mv s0, a0
    jal fileSize
    li t0, 0x0FFFF
    bgt a0, t0, loader.text_size_err

    mv a2, a0
    mv a0, s0
    li a7, 63
    DE1(s8,loader.DE1_text) # se for DE1, ler direto no .text
    li a1, 0x10010000       # se nao, ler no .data
    ecall

    srai t0, a2, 2      # quantas words de codigo
    li t2, 0x10010000
    li t3, 0x00400000
loader.rars_text: lw t4, 0(t2)
    sw t4, 0(t3)
    addi t2, t2, 4
    addi t3, t3, 4
    addi t0, t0, -1
    bgtz t0, loader.rars_text
    j loader.load_data

 loader.DE1_text: li a1, 0x00400000
    ecall   # carrega secao de codigo

loader.load_data: mv a0, s0
    li a7, 57
    ecall   # fecha arquivo .bin

    la a0, buffer
    addi a0, a0, 5
# trocar a extensao do arquivo para .dat
    li t0, 't'
    sb t0, 0(s2)
    li t0, 'a'
    sb t0, -1(s2)
    li t0, 'd'
    sb t0, -2(s2)

    li a1, 0
    li a7, 1024
    ecall   # abre o arquivo de dados
    bltz a0, loader.no_dat_file_err
    mv s0, a0
    jal fileSize
    li t0, 0x1FFFF
    bgt a0, t0, loader.data_size_err

    mv a2, a0
    mv a0, s0
    li a1, 0x10010000
    li a7, 63
    ecall   # carrega a secao de dados
    mv a0, s0
    li a7, 57
    ecall   # fecha arquivo .dat
    li t0, 0x00400000
    jr t0

loader.no_bin_file_err: la a0, no_bin_file_error
    j loader.print_err

loader.no_dat_file_err: la a0, no_dat_file_error
    j loader.print_err

loader.text_size_err: la a0, text_size_error
    j loader.print_err

loader.data_size_err: la a0, data_size_error
    j loader.print_err


loader.print_err: jal shell.print_line
    jal shell.inc_line
    j shell.reset_buffer
