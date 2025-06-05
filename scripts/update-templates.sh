#!/bin/bash

# dotrules テンプレート更新スクリプト
# 既存プロジェクトのテンプレートファイルを最新版に更新します

set -e

# 色付きメッセージ用の関数
print_info() {
    echo -e "\033[34mℹ️  $1\033[0m"
}

print_success() {
    echo -e "\033[32m✅ $1\033[0m"
}

print_warning() {
    echo -e "\033[33m⚠️  $1\033[0m"
}

print_error() {
    echo -e "\033[31m❌ $1\033[0m"
}

# dotrulesディレクトリのパスを検出
detect_dotrules_path() {
    local possible_paths=(
        "$HOME/dotrules"
        "$HOME/dev/dotrules"
        "$DOTRULES_PATH"
        "$(dirname "$0")/.."
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -n "$path" && -d "$path" && -f "$path/README.md" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# ファイルのバックアップを作成
create_backup() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup_file"
        print_info "バックアップを作成: $backup_file"
        echo "$backup_file"
    fi
}

# テンプレートファイルを更新
update_template_file() {
    local template_file="$1"
    local target_file="$2"
    local force_update="$3"
    
    if [[ ! -f "$template_file" ]]; then
        print_warning "テンプレートファイルが見つかりません: $template_file"
        return 1
    fi
    
    if [[ ! -f "$target_file" ]]; then
        print_info "$(basename "$target_file")が存在しません。新規作成します。"
        cp "$template_file" "$target_file"
        print_success "$(basename "$target_file")を作成しました"
        return 0
    fi
    
    # ファイルの違いをチェック
    if cmp -s "$template_file" "$target_file"; then
        print_info "$(basename "$target_file")は既に最新版です"
        return 0
    fi
    
    # 強制更新が指定されていない場合は確認
    if [[ "$force_update" != "true" ]]; then
        print_warning "$(basename "$target_file")に変更があります"
        print_info "違いを表示しますか? (y/N)"
        read -p "> " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            diff -u "$target_file" "$template_file" || true
        fi
        
        print_info "$(basename "$target_file")を更新しますか? (y/N)"
        read -p "> " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "$(basename "$target_file")の更新をスキップしました"
            return 0
        fi
    fi
    
    # バックアップを作成して更新
    local backup_file=$(create_backup "$target_file")
    cp "$template_file" "$target_file"
    print_success "$(basename "$target_file")を更新しました"
    
    if [[ -n "$backup_file" ]]; then
        print_info "以前のファイルをバックアップ: $backup_file"
    fi
}

# 設定ファイルの更新
update_config_files() {
    local dotrules_dir="$1"
    local force_update="$2"
    local templates_dir="$dotrules_dir/templates"
    
    print_info "設定ファイルを更新中..."
    
    # TypeScriptプロジェクトの場合
    if [[ -f "package.json" ]] && grep -q "typescript" package.json 2>/dev/null; then
        update_template_file "$templates_dir/tsconfig.json.template" "./tsconfig.json" "$force_update"
        update_template_file "$templates_dir/vitest.config.ts.template" "./vitest.config.ts" "$force_update"
        update_template_file "$templates_dir/vitest.integration.config.ts.template" "./vitest.integration.config.ts" "$force_update"
        update_template_file "$templates_dir/vitest.setup.ts.template" "./vitest.setup.ts" "$force_update"
        update_template_file "$templates_dir/vitest.integration.setup.ts.template" "./vitest.integration.setup.ts" "$force_update"
    fi
}

# CLAUDE.mdの更新
update_claude_md() {
    local dotrules_dir="$1"
    local force_update="$2"
    local template_file="$dotrules_dir/templates/CLAUDE.md.template"
    local target_file="./CLAUDE.md"
    
    if [[ ! -f "$target_file" ]]; then
        print_info "CLAUDE.mdが存在しません。作成しますか? (y/N)"
        read -p "> " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            local relative_path=$(realpath --relative-to="$(pwd)" "$dotrules_dir" 2>/dev/null || echo "$dotrules_dir")
            sed "s|PATH_TO_DOTRULES|$relative_path|g" "$template_file" > "$target_file"
            print_success "CLAUDE.mdを作成しました"
        fi
        return
    fi
    
    # CLAUDE.mdは手動での更新を推奨
    if [[ "$force_update" != "true" ]]; then
        print_warning "CLAUDE.mdはプロジェクト固有の内容が含まれているため、自動更新をスキップします"
        print_info "最新のテンプレートと比較したい場合は、以下のファイルを参照してください:"
        print_info "  - テンプレート: $template_file"
        return
    fi
    
    # 強制更新の場合のみ更新
    local backup_file=$(create_backup "$target_file")
    local relative_path=$(realpath --relative-to="$(pwd)" "$dotrules_dir" 2>/dev/null || echo "$dotrules_dir")
    sed "s|PATH_TO_DOTRULES|$relative_path|g" "$template_file" > "$target_file"
    print_success "CLAUDE.mdを更新しました（注意: プロジェクト固有の内容が失われた可能性があります）"
    
    if [[ -n "$backup_file" ]]; then
        print_warning "バックアップから必要な内容を復元してください: $backup_file"
    fi
}

# package.jsonスニペットの表示
show_package_json_snippets() {
    local dotrules_dir="$1"
    local snippets_file="$dotrules_dir/templates/package.json.snippets"
    
    if [[ -f "package.json" ]]; then
        print_info "package.jsonの推奨スクリプトについては以下を参照してください:"
        print_info "  - ファイル: $snippets_file"
        print_info "  - 内容を確認して必要なスクリプトを手動で追加してください"
    fi
}

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  -f, --force    確認なしで強制的に更新"
    echo "  -h, --help     このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0              # 対話的に更新"
    echo "  $0 --force      # 強制的に更新"
}

# メイン処理
main() {
    local force_update="false"
    
    # コマンドライン引数の解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_update="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "不明なオプション: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_info "dotrules テンプレート更新を開始します..."
    
    # dotrulesディレクトリを検出
    DOTRULES_DIR=$(detect_dotrules_path)
    if [[ $? -ne 0 ]]; then
        print_error "dotrulesディレクトリが見つかりません"
        exit 1
    fi
    
    print_success "dotrulesディレクトリを検出: $DOTRULES_DIR"
    
    # dotrulesリポジトリを更新
    print_info "dotrulesリポジトリを更新中..."
    (cd "$DOTRULES_DIR" && git pull origin main) || print_warning "dotrulesリポジトリの更新に失敗しました"
    
    # 設定ファイルの更新
    update_config_files "$DOTRULES_DIR" "$force_update"
    
    # CLAUDE.mdの更新
    update_claude_md "$DOTRULES_DIR" "$force_update"
    
    # package.jsonスニペットの表示
    show_package_json_snippets "$DOTRULES_DIR"
    
    print_success "🎉 テンプレート更新が完了しました！"
    
    if [[ "$force_update" == "false" ]]; then
        print_info "変更されたファイルがある場合は、内容を確認してコミットしてください"
    fi
}

# スクリプトの実行
main "$@"