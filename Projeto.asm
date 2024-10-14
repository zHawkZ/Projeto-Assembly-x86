.686
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\msvcrt.inc
include \masm32\include\masm32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\msvcrt.lib
includelib \masm32\lib\masm32.lib
include \masm32\macros\macros.asm

.data

;[Prompts de solitação]
prompt_soliciticao_entrada db "Digite o nome do arquivo de entrada: ", 0H
prompt_soliciticao_saida db "Digite o nome do arquivo de saida: ", 0H
prompt_soliciticao_constante_reducao_volume db "Digite a constante de reducao desejada: ", 0H
;[Prompts de solitação]


;[Nome dos arquivos de entrada e saída]
input_nome_arquivo db 50 dup(0)
output_nome_arquivo db 50 dup(0)
;[Nome dos arquivos de entrada e saída]


;[Buffers de leitura dos arquivos desejados]
bytes_arquivo_cabecalho db 44 dup(0)
bytes_arquivo_entrada db 16 dup(0)
buffer_bytes_modificados db 16 dup(0)
;[Buffers de leitura dos arquivos desejados]


;[Handles necessários para saida e entrada de dados no console]
inputHandle dd ?
outputHandle dd ?
;[Handles necessários para saida e entrada de dados no console]


;[Handles necessários para manipulação dos arquivos criados]
fileHandle_abertura_original dd ?
fileHandle_criacao_novo dd ?
;[Handles necessários para manipulação dos arquivos criados]


;[retorno da quantidade de caracteres da função write console]
console_count dd ?
;[retorno da quantidade de caracteres da função write console]


;[retorno da quantidade de caracteres lidos ou escritos durante a leitura e escrita em arquivos]
readCount dd ?
writeCount dd ?
;[retorno da quantidade de caracteres lidos ou escritos durante a leitura e escrita em arquivos]


;[Necessário após o tratamento de um string recebida pelo console]
tamanho_real_string dd ?
;[Necessário após o tratamento de um string recebida pelo console]


;[Variável do tipo byte para receber incialmente a string numérica do console e variável do tipo inteira para armazenar o valor tratado vindo do console]
input_reducao_volume db 5 dup(0)
CONSTANTE_REDUCAO_VOLUME dw ?
;[Variável do tipo byte para receber incialmente a string numérica do console e variável do tipo inteira para armazenar o valor tratado vindo do console]

.code

;Função que trata as strings recebidas pelo console[AMÉM]

trata_strings:
 mov al, [esi] 
 inc esi 
 cmp al, 13 
    jne trata_strings
 dec esi 
 xor al, al 
 mov [esi], al
 ret 

le_bytes_cabecalho:
  invoke ReadFile, fileHandle_abertura_original, addr bytes_arquivo_cabecalho, 44, addr readCount, NULL
  invoke WriteFile, fileHandle_criacao_novo, addr bytes_arquivo_cabecalho, 44, addr writeCount, NULL
  ret

start:

    ;[Solitação dos handles de saida e entrada]
     
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax

    ;[solitações de input para o usuario]
    
    invoke WriteConsole, outputHandle, addr prompt_soliciticao_entrada, sizeof prompt_soliciticao_entrada, addr console_count, NULL   
    invoke ReadConsole, inputHandle, addr input_nome_arquivo, sizeof input_nome_arquivo, addr console_count, NULL

    invoke WriteConsole, outputHandle, addr prompt_soliciticao_saida, sizeof prompt_soliciticao_saida, addr console_count, NULL
    invoke ReadConsole, inputHandle, addr output_nome_arquivo, sizeof output_nome_arquivo, addr console_count, NULL

    invoke WriteConsole, outputHandle, addr prompt_soliciticao_constante_reducao_volume, sizeof prompt_soliciticao_constante_reducao_volume, addr console_count, NULL   
    invoke ReadConsole, inputHandle, addr input_reducao_volume, sizeof input_reducao_volume, addr console_count, NULL


    ; [tratamento das strings recebidas pelo console]

    mov esi, offset input_nome_arquivo ; 
    call trata_strings

    mov esi, offset output_nome_arquivo ; 
    call trata_strings

    mov esi, offset input_reducao_volume 
    call trata_strings
    invoke atodw, addr input_reducao_volume
    mov CONSTANTE_REDUCAO_VOLUME, ax


    ; abertura de arquivo ja existente
    invoke CreateFile, addr input_nome_arquivo , GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    mov fileHandle_abertura_original, eax

    ;Criando um arquivo novo
    invoke CreateFile, addr output_nome_arquivo , GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    mov fileHandle_criacao_novo, eax

    ;le dados dos cabecalho
    call le_bytes_cabecalho


        
    le_de_dezesseis_em_dezesseis_bytes:
        invoke ReadFile, fileHandle_abertura_original, addr bytes_arquivo_entrada, 16, addr readCount, NULL
        cmp readCount, 0
        je fimLeitura
        xor ecx, ecx
        le_dois_bytes_em_dois_bytes:
            mov ax, word PTR[bytes_arquivo_entrada + 2*ecx]
            cwd
            mov bx, CONSTANTE_REDUCAO_VOLUME
            idiv bx
            mov WORD PTR[buffer_bytes_modificados + 2*ecx], ax
            inc ecx
            cmp ecx, 8
            jl le_dois_bytes_em_dois_bytes
            invoke WriteFile, fileHandle_criacao_novo, addr buffer_bytes_modificados, 16, addr readCount, NULL
            jmp le_de_dezesseis_em_dezesseis_bytes
                       

    fimLeitura:
        invoke CloseHandle, fileHandle_abertura_original
        invoke CloseHandle, fileHandle_criacao_novo   
        invoke ExitProcess, 0
end start
