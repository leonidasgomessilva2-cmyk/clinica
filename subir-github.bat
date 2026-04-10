@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Upload automatico para GitHub
color 0A

cd /d "%~dp0"
set "LOGFILE=%~dp0upload-github-log.txt"
break > "%LOGFILE%"

echo ==========================================
echo   UPLOAD AUTOMATICO PARA O GITHUB
echo ==========================================
echo.
echo Log desta execucao:
echo %LOGFILE%
echo.

where git >nul 2>nul
if errorlevel 1 (
    set "ERRMSG=Git nao esta instalado ou nao esta no PATH."
    goto :erro
)

git rev-parse --is-inside-work-tree >nul 2>>"%LOGFILE%"
if errorlevel 1 (
    echo Inicializando repositorio Git...
    git init >>"%LOGFILE%" 2>&1
    if errorlevel 1 (
        set "ERRMSG=Falha ao inicializar o repositorio Git."
        goto :erro
    )
)

for /f "delims=" %%i in ('git config --get user.name 2^>nul') do set "GIT_USER_NAME=%%i"
for /f "delims=" %%i in ('git config --get user.email 2^>nul') do set "GIT_USER_EMAIL=%%i"

if not defined GIT_USER_NAME (
    set "ERRMSG=O Git nao possui user.name configurado. Execute: git config --global user.name ""Seu Nome"""
    goto :erro
)

if not defined GIT_USER_EMAIL (
    set "ERRMSG=O Git nao possui user.email configurado. Execute: git config --global user.email ""seuemail@exemplo.com"""
    goto :erro
)

echo Informe a URL do repositorio de destino.
echo Exemplo:
echo https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git
echo.
set /p REPO_URL=Repositorio: 

if not defined REPO_URL (
    set "ERRMSG=Nenhuma URL de repositorio foi informada."
    goto :erro
)

git remote get-url origin >nul 2>>"%LOGFILE%"
if errorlevel 1 (
    echo Configurando remoto origin...
    git remote add origin "!REPO_URL!" >>"%LOGFILE%" 2>&1
    if errorlevel 1 (
        set "ERRMSG=Falha ao adicionar o remoto origin."
        goto :erro
    )
) else (
    for /f "delims=" %%i in ('git remote get-url origin 2^>nul') do set "REMOTE_ATUAL=%%i"
    if /I not "!REMOTE_ATUAL!"=="!REPO_URL!" (
        echo Atualizando remoto origin...
        git remote set-url origin "!REPO_URL!" >>"%LOGFILE%" 2>&1
        if errorlevel 1 (
            set "ERRMSG=Falha ao atualizar a URL do remoto origin."
            goto :erro
        )
    )
)

echo.
echo Adicionando arquivos...
git add -A >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    set "ERRMSG=Falha ao adicionar os arquivos com git add -A."
    goto :erro
)

set "HAS_CHANGES="
for /f %%i in ('git status --porcelain ^| find /c /v ""') do set "HAS_CHANGES=%%i"

if "!HAS_CHANGES!"=="0" (
    echo Nenhuma alteracao encontrada. Nada para enviar.
    echo.
    echo Verifique se:
    echo 1. voce realmente salvou alteracoes nesta pasta
    echo 2. os arquivos nao estao no .gitignore
    echo 3. o .bat esta dentro da pasta correta do projeto
    goto :fim
)

echo.
set /p COMMIT_MSG=Mensagem do commit [Enter para usar a padrao]: 
if not defined COMMIT_MSG set "COMMIT_MSG=Atualizacao %date% %time%"

echo.
echo Criando commit...
git commit -m "!COMMIT_MSG!" >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    set "ERRMSG=Falha ao criar o commit."
    goto :erro
)

echo Ajustando branch principal para main...
git branch -M main >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    set "ERRMSG=Falha ao ajustar a branch para main."
    goto :erro
)

echo.
echo Enviando para o GitHub...
git push -u origin main >>"%LOGFILE%" 2>&1
if errorlevel 1 (
    set "ERRMSG=Falha no push para o GitHub. Veja o log para identificar se foi autenticacao, permissao ou conflito."
    goto :erro
)

echo.
echo ==========================================
echo   SUCESSO: PROJETO ENVIADO AO GITHUB
echo ==========================================
echo Repositorio: !REPO_URL!
echo Branch: main
goto :fim

:erro
echo.
echo ==========================================
echo   ERRO
echo ==========================================
echo !ERRMSG!
echo.
echo Abra este arquivo para ver o detalhe:
echo %LOGFILE%
echo.

:fim
pause
endlocal