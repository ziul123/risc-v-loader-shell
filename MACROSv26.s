.macro m1
nop
nop
.end_macro
.macro m3
m1
m1
m1
m1
.end_macro
.macro m5
m3
m3
m3
m3
.end_macro
.macro m7
m5
m5
m5
m5
.end_macro
.macro m9
m7
m7
m7
m7
.end_macro
.macro m11
m9
m9
m9
m9
.end_macro
.macro m13
m11
m11
m11
m11
.end_macro
.macro m_final
nop
m1
m3
m3
m3
m5
m5
m5
m7
m7
m7
m9
m9
m9
m11
m11
m11
m13
.end_macro
.data
#.space 131072
.space 65536
.align 2
.text
 	la 	tp, ExceptionHandling	# carrega em tp o endere�o base das rotinas do sistema ECALL
 	csrw 	tp, utvec 		# seta utvec para o endere�o tp
 	csrsi 	ustatus, 1 
