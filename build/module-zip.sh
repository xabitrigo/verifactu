#!/bin/sh
# Genera dist/module_verifactu-<versión>.zip, instalable desde Dolibarr en
# Inicio > Configuración > Módulos > Instalar un módulo externo. Dolibarr exige
# ese nombre de fichero y una carpeta verifactu/ en la raíz del zip.
#
# Uso: build/module-zip.sh [commit]   (por defecto HEAD)
# Empaqueta el commit, no la copia de trabajo: lo que no esté confirmado no entra.
set -eu

cd "$(git rev-parse --show-toplevel)"
ref=${1:-HEAD}

leer() {
	git show "$ref:$1" | sed -n "s/$2/\1/p" | head -1
}
modulo=$(leer core/modules/modVerifactu.class.php ".*verifactu_version = '\([0-9.]*\)'.*")
declaracion=$(leer conf/declaracion_responsable.conf.php ".*'version' => '\([0-9.]*\)',.*")
respaldo=$(leer lib/functions/functions.configuration.php ".*'version' => '\([0-9.]*\)',.*")

# Ese número viaja a la AEAT en el campo Version: tiene que coincidir en los tres sitios
if [ -z "$modulo" ] || [ "$modulo" != "$declaracion" ] || [ "$modulo" != "$respaldo" ]; then
	echo "La versión no coincide: modVerifactu=$modulo declaración=$declaracion respaldo=$respaldo" >&2
	exit 1
fi

if [ "$ref" = HEAD ] && [ -n "$(git status --porcelain --untracked-files=no)" ]; then
	echo "Aviso: hay cambios sin confirmar; no entran en el zip." >&2
fi

mkdir -p dist
zip="dist/module_verifactu-$modulo.zip"
# autocrlf desactivado: el zip lleva los ficheros tal cual están en el repositorio
git -c core.autocrlf=false archive --format=zip --prefix=verifactu/ -o "$zip" "$ref" -- \
	. ':(exclude).github' ':(exclude).gitignore' ':(exclude)build' ':(exclude)tests' ':(exclude)wiki'

echo "$zip"
