#!/bin/bash

# Скрипт для автоматической сборки архива для сдачи задания
# Использование: ./build_archive.sh [формат]
# Форматы: tar.gz (по умолчанию), zip, both

set -e  # Остановка при ошибках

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Параметры
ARCHIVE_FORMAT="${1:-tar.gz}"
ARCHIVE_NAME="user_manager_microservice"
TEMP_DIR="archive_temp_$$"

# Функция для вывода сообщений
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Очистка при выходе
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        info "Временная директория удалена"
    fi
}
trap cleanup EXIT

echo "=========================================="
echo "  Сборка архива для сдачи задания"
echo "=========================================="
echo ""

# Проверка наличия необходимых файлов
info "Проверка наличия необходимых файлов..."

REQUIRED_FILES=(
    "main.go"
    "go.mod"
    "go.sum"
    "Dockerfile"
    "docker-compose.yml"
    "handlers/user_handler.go"
    "services/user_service.go"
    "models/user.go"
    "utils/logger.go"
    "utils/rate_limiter.go"
    "metrics/prometheus.go"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    warning "Обнаружены отсутствующие файлы:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    read -p "Продолжить сборку? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Сборка отменена"
        exit 1
    fi
else
    success "Все необходимые файлы найдены"
fi

# Создание временной директории
info "Создание временной директории..."
mkdir -p "$TEMP_DIR"

# Копирование файлов
info "Копирование файлов..."

# Копируем директории с исходным кодом
for dir in handlers services models utils metrics; do
    if [ -d "$dir" ]; then
        mkdir -p "$TEMP_DIR/$dir"
        cp -r "$dir"/*.go "$TEMP_DIR/$dir/" 2>/dev/null || true
        success "  Скопирована директория: $dir/"
    fi
done

# Копируем основные файлы
cp main.go "$TEMP_DIR/" 2>/dev/null && success "  Скопирован: main.go" || warning "  Не найден: main.go"
cp go.mod "$TEMP_DIR/" 2>/dev/null && success "  Скопирован: go.mod" || warning "  Не найден: go.mod"
cp go.sum "$TEMP_DIR/" 2>/dev/null && success "  Скопирован: go.sum" || warning "  Не найден: go.sum"
cp Dockerfile "$TEMP_DIR/" 2>/dev/null && success "  Скопирован: Dockerfile" || warning "  Не найден: Dockerfile"
cp docker-compose.yml "$TEMP_DIR/" 2>/dev/null && success "  Скопирован: docker-compose.yml" || warning "  Не найден: docker-compose.yml"

# Проверка наличия отчета (опционально)
if ls *.docx 2>/dev/null | grep -q .; then
    REPORT_FILE=$(ls *.docx 2>/dev/null | head -1)
    cp "$REPORT_FILE" "$TEMP_DIR/" 2>/dev/null && success "  Скопирован отчет: $REPORT_FILE" || warning "  Не удалось скопировать отчет"
elif ls report*.docx 2>/dev/null | grep -q .; then
    REPORT_FILE=$(ls report*.docx 2>/dev/null | head -1)
    cp "$REPORT_FILE" "$TEMP_DIR/" 2>/dev/null && success "  Скопирован отчет: $REPORT_FILE" || warning "  Не удалось скопировать отчет"
else
    info "  Отчет (.docx) не найден (будет добавлен позже)"
fi

# Проверка содержимого
info "Проверка содержимого архива..."
FILE_COUNT=$(find "$TEMP_DIR" -type f | wc -l | tr -d ' ')
success "Найдено файлов: $FILE_COUNT"

echo ""
info "Содержимое архива:"
find "$TEMP_DIR" -type f | sed "s|^$TEMP_DIR/|  |" | sort

# Создание архива
echo ""
info "Создание архива..."

case "$ARCHIVE_FORMAT" in
    tar.gz)
        ARCHIVE_FILE="${ARCHIVE_NAME}.tar.gz"
        cd "$TEMP_DIR"
        tar -czf "../$ARCHIVE_FILE" .
        cd ..
        success "Создан архив: $ARCHIVE_FILE"
        ls -lh "$ARCHIVE_FILE" | awk '{print "  Размер: " $5}'
        ;;
    zip)
        ARCHIVE_FILE="${ARCHIVE_NAME}.zip"
        cd "$TEMP_DIR"
        zip -r "../$ARCHIVE_FILE" . > /dev/null
        cd ..
        success "Создан архив: $ARCHIVE_FILE"
        ls -lh "$ARCHIVE_FILE" | awk '{print "  Размер: " $5}'
        ;;
    both)
        # TAR.GZ
        ARCHIVE_FILE_TAR="${ARCHIVE_NAME}.tar.gz"
        cd "$TEMP_DIR"
        tar -czf "../$ARCHIVE_FILE_TAR" .
        cd ..
        success "Создан архив: $ARCHIVE_FILE_TAR"
        ls -lh "$ARCHIVE_FILE_TAR" | awk '{print "  Размер: " $5}'
        
        # ZIP
        ARCHIVE_FILE_ZIP="${ARCHIVE_NAME}.zip"
        cd "$TEMP_DIR"
        zip -r "../$ARCHIVE_FILE_ZIP" . > /dev/null
        cd ..
        success "Создан архив: $ARCHIVE_FILE_ZIP"
        ls -lh "$ARCHIVE_FILE_ZIP" | awk '{print "  Размер: " $5}'
        ;;
    *)
        warning "Неизвестный формат: $ARCHIVE_FORMAT"
        echo "Используйте: tar.gz, zip или both"
        exit 1
        ;;
esac

# Проверка архива
echo ""
info "Проверка архива..."

if [ "$ARCHIVE_FORMAT" = "both" ]; then
    # Проверка TAR.GZ
    if tar -tzf "$ARCHIVE_FILE_TAR" > /dev/null 2>&1; then
        success "Архив $ARCHIVE_FILE_TAR корректен"
    else
        warning "Ошибка в архиве $ARCHIVE_FILE_TAR"
    fi
    
    # Проверка ZIP
    if unzip -t "$ARCHIVE_FILE_ZIP" > /dev/null 2>&1; then
        success "Архив $ARCHIVE_FILE_ZIP корректен"
    else
        warning "Ошибка в архиве $ARCHIVE_FILE_ZIP"
    fi
else
    if [ "$ARCHIVE_FORMAT" = "tar.gz" ]; then
        if tar -tzf "$ARCHIVE_FILE" > /dev/null 2>&1; then
            success "Архив $ARCHIVE_FILE корректен"
        else
            warning "Ошибка в архиве $ARCHIVE_FILE"
        fi
    else
        if unzip -t "$ARCHIVE_FILE" > /dev/null 2>&1; then
            success "Архив $ARCHIVE_FILE корректен"
        else
            warning "Ошибка в архиве $ARCHIVE_FILE"
        fi
    fi
fi

# Итоговая информация
echo ""
echo "=========================================="
success "Архив успешно создан!"
echo "=========================================="
echo ""
echo "Содержимое архива:"
if [ "$ARCHIVE_FORMAT" = "both" ]; then
    echo "  - $ARCHIVE_FILE_TAR"
    echo "  - $ARCHIVE_FILE_ZIP"
else
    echo "  - $ARCHIVE_FILE"
fi
echo ""
echo "Файлы в архиве:"
if [ "$ARCHIVE_FORMAT" = "both" ] || [ "$ARCHIVE_FORMAT" = "tar.gz" ]; then
    echo "  (tar.gz):"
    tar -tzf "${ARCHIVE_NAME}.tar.gz" 2>/dev/null | grep -E '\.(go|mod|sum)$|Dockerfile|docker-compose' | sed 's/^/    /' | head -15
fi
echo ""
info "Для добавления отчета (.docx) добавьте файл вручную или пересоберите архив"
echo ""

