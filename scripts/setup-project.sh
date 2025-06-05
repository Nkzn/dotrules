#!/bin/bash

# dotrules プロジェクトセットアップスクリプト
# 新規プロジェクトにdotrulesテンプレートを適用します

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

# メイン処理
main() {
    print_info "dotrules プロジェクトセットアップを開始します..."
    
    # dotrulesディレクトリを検出
    DOTRULES_DIR=$(detect_dotrules_path)
    if [[ $? -ne 0 ]]; then
        print_error "dotrulesディレクトリが見つかりません"
        print_info "以下のいずれかの場所にdotrulesをクローンしてください:"
        print_info "  - $HOME/dotrules"
        print_info "  - $HOME/dev/dotrules"
        print_info "または DOTRULES_PATH 環境変数を設定してください"
        exit 1
    fi
    
    print_success "dotrulesディレクトリを検出: $DOTRULES_DIR"
    
    # 現在のディレクトリをチェック
    if [[ ! -f "package.json" && ! -f "Cargo.toml" && ! -f "go.mod" ]]; then
        print_warning "プロジェクトディレクトリではない可能性があります"
        read -p "続行しますか? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "セットアップをキャンセルしました"
            exit 0
        fi
    fi
    
    # CLAUDE.mdのセットアップ
    setup_claude_md "$DOTRULES_DIR"
    
    # 設定ファイルのセットアップ
    setup_config_files "$DOTRULES_DIR"
    
    # package.jsonの更新（Node.jsプロジェクトの場合）
    if [[ -f "package.json" ]]; then
        setup_package_json "$DOTRULES_DIR"
    fi
    
    print_success "🎉 dotrulesセットアップが完了しました！"
    print_info "次のステップ:"
    print_info "  1. CLAUDE.mdを編集してプロジェクト固有の情報を追加"
    print_info "  2. 設定ファイルをプロジェクトに合わせて調整"
    print_info "  3. npm install または適切なパッケージマネージャーで依存関係をインストール"
}

# CLAUDE.mdのセットアップ
setup_claude_md() {
    local dotrules_dir="$1"
    local template_file="$dotrules_dir/templates/CLAUDE.md.template"
    local target_file="./CLAUDE.md"
    
    if [[ -f "$target_file" ]]; then
        print_warning "CLAUDE.mdが既に存在します"
        read -p "上書きしますか? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "CLAUDE.mdの作成をスキップしました"
            return
        fi
    fi
    
    # テンプレートをコピーしてパスを置換
    local relative_path=$(realpath --relative-to="$(pwd)" "$dotrules_dir" 2>/dev/null || echo "$dotrules_dir")
    sed "s|PATH_TO_DOTRULES|$relative_path|g" "$template_file" > "$target_file"
    
    print_success "CLAUDE.mdを作成しました"
}

# 設定ファイルのセットアップ
setup_config_files() {
    local dotrules_dir="$1"
    local templates_dir="$dotrules_dir/templates"
    
    # TypeScriptプロジェクトの場合
    if [[ -f "package.json" ]] && grep -q "typescript" package.json 2>/dev/null; then
        copy_template_if_not_exists "$templates_dir/tsconfig.json.template" "./tsconfig.json"
        copy_template_if_not_exists "$templates_dir/vitest.config.ts.template" "./vitest.config.ts"
        copy_template_if_not_exists "$templates_dir/vitest.integration.config.ts.template" "./vitest.integration.config.ts"
        copy_template_if_not_exists "$templates_dir/vitest.setup.ts.template" "./vitest.setup.ts"
        copy_template_if_not_exists "$templates_dir/vitest.integration.setup.ts.template" "./vitest.integration.setup.ts"
    fi
}

# package.jsonの更新
setup_package_json() {
    local dotrules_dir="$1"
    local snippets_file="$dotrules_dir/templates/package.json.snippets"
    
    print_info "package.json.snippetsを参考にスクリプトを追加してください:"
    print_info "  - ファイル: $snippets_file"
    print_info "  - 推奨スクリプト: test, test:integration, lint, typecheck など"
}

# テンプレートファイルをコピー（存在しない場合のみ）
copy_template_if_not_exists() {
    local template_file="$1"
    local target_file="$2"
    
    if [[ -f "$target_file" ]]; then
        print_warning "$(basename "$target_file")が既に存在します（スキップ）"
        return
    fi
    
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$target_file"
        print_success "$(basename "$target_file")を作成しました"
    else
        print_warning "テンプレートファイルが見つかりません: $template_file"
    fi
}

# スクリプトの実行
main "$@"