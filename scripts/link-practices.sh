#!/bin/bash

# dotrules ベストプラクティスリンクスクリプト
# 既存プロジェクトにdotrulesベストプラクティスへの参照を追加します

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

# CLAUDE.mdにベストプラクティス参照を追加
add_best_practices_to_claude_md() {
    local dotrules_dir="$1"
    local claude_md="./CLAUDE.md"
    local relative_path=$(realpath --relative-to="$(pwd)" "$dotrules_dir" 2>/dev/null || echo "$dotrules_dir")
    
    if [[ ! -f "$claude_md" ]]; then
        print_warning "CLAUDE.mdが存在しません。作成しますか?"
        read -p "(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_basic_claude_md "$relative_path"
            return
        else
            print_info "CLAUDE.mdの作成をスキップしました"
            return
        fi
    fi
    
    # 既にベストプラクティス参照が存在するかチェック
    if grep -q "dotrules" "$claude_md" 2>/dev/null; then
        print_warning "CLAUDE.mdに既にdotrulesの参照が存在します"
        read -p "更新しますか? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "CLAUDE.mdの更新をスキップしました"
            return
        fi
    fi
    
    # バックアップを作成
    cp "$claude_md" "${claude_md}.backup"
    print_info "CLAUDE.mdのバックアップを作成: ${claude_md}.backup"
    
    # ベストプラクティスセクションを追加
    add_best_practices_section "$claude_md" "$relative_path"
    
    print_success "CLAUDE.mdにベストプラクティス参照を追加しました"
}

# 基本的なCLAUDE.mdを作成
create_basic_claude_md() {
    local relative_path="$1"
    
    cat > "./CLAUDE.md" << EOF
# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリのコードを扱う際のガイダンスを提供します。

## プロジェクト概要

[プロジェクトの説明をここに記載]

## ベストプラクティス参照

このプロジェクトは [dotrules](https://github.com/Nkzn/dotrules) のベストプラクティスに従って開発されています：

- [テスト戦略]($relative_path/best-practices/testing-strategy-best-practices.md)
- [HonoXパターン]($relative_path/best-practices/honox-best-practices.md)
- [Prismaガイドライン]($relative_path/best-practices/prisma-best-practices.md)
- [開発ワークフロー]($relative_path/best-practices/development-commit-strategy.md)

## 開発コマンド

\`\`\`bash
# 開発サーバー起動
npm run dev

# テスト実行
npm run test
npm run test:integration

# 品質チェック
npm run lint
npm run typecheck
\`\`\`

## プロジェクト固有のガイドライン

[プロジェクト固有の内容をここに記載]
EOF

    print_success "基本的なCLAUDE.mdを作成しました"
}

# ベストプラクティスセクションを追加
add_best_practices_section() {
    local claude_md="$1"
    local relative_path="$2"
    
    # 既存のdotrules参照を削除
    sed -i.tmp '/## ベストプラクティス参照/,/^## /{ /^## ベストプラクティス参照/d; /^## /!d; }' "$claude_md"
    
    # プロジェクト概要の後にベストプラクティスセクションを挿入
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << EOF

## ベストプラクティス参照

このプロジェクトは [dotrules](https://github.com/Nkzn/dotrules) のベストプラクティスに従って開発されています：

- [テスト戦略]($relative_path/best-practices/testing-strategy-best-practices.md)
- [HonoXパターン]($relative_path/best-practices/honox-best-practices.md)  
- [Prismaガイドライン]($relative_path/best-practices/prisma-best-practices.md)
- [開発ワークフロー]($relative_path/best-practices/development-commit-strategy.md)

EOF
    
    # プロジェクト概要セクションの後に挿入
    if grep -q "## プロジェクト概要" "$claude_md"; then
        # プロジェクト概要セクションの後に挿入
        awk '
            /^## プロジェクト概要/ { print; getline; print; while (getline && !/^## /) print; print ""; while (getline < "'$temp_file'") print; print; next }
            { print }
        ' "$claude_md" > "${claude_md}.new"
        mv "${claude_md}.new" "$claude_md"
    else
        # 先頭に挿入
        cat "$temp_file" "$claude_md" > "${claude_md}.new"
        mv "${claude_md}.new" "$claude_md"
    fi
    
    rm -f "$temp_file" "${claude_md}.tmp"
}

# READMEファイルの作成/更新
update_readme() {
    local dotrules_dir="$1"
    local readme_file="./README.md"
    
    if [[ ! -f "$readme_file" ]]; then
        print_info "README.mdが存在しません。基本的なREADMEを作成しますか?"
        read -p "(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_basic_readme
        fi
        return
    fi
    
    # dotrulesバッジを追加
    if ! grep -q "dotrules" "$readme_file" 2>/dev/null; then
        print_info "README.mdにdotrulesバッジを追加しますか?"
        read -p "(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            add_dotrules_badge "$readme_file"
        fi
    fi
}

# 基本的なREADMEを作成
create_basic_readme() {
    cat > "./README.md" << 'EOF'
# Project Name

[![dotrules](https://img.shields.io/badge/follows-dotrules-blue)](https://github.com/Nkzn/dotrules)

[プロジェクトの説明]

## 開発

このプロジェクトは [dotrules](https://github.com/Nkzn/dotrules) のベストプラクティスに従って開発されています。

### セットアップ

```bash
npm install
```

### 開発サーバー起動

```bash
npm run dev
```

### テスト実行

```bash
npm run test           # ユニットテスト
npm run test:integration # 統合テスト
```

### 品質チェック

```bash
npm run lint
npm run typecheck
```
EOF

    print_success "基本的なREADME.mdを作成しました"
}

# dotrulesバッジを追加
add_dotrules_badge() {
    local readme_file="$1"
    local temp_file=$(mktemp)
    
    # タイトルの後にバッジを追加
    awk '
        /^# / && !badge_added { 
            print
            print ""
            print "[![dotrules](https://img.shields.io/badge/follows-dotrules-blue)](https://github.com/Nkzn/dotrules)"
            badge_added = 1
            next
        }
        { print }
    ' "$readme_file" > "$temp_file"
    
    mv "$temp_file" "$readme_file"
    print_success "README.mdにdotrulesバッジを追加しました"
}

# メイン処理
main() {
    print_info "dotrules ベストプラクティスリンクを開始します..."
    
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
    
    # CLAUDE.mdの更新
    add_best_practices_to_claude_md "$DOTRULES_DIR"
    
    # README.mdの更新
    update_readme "$DOTRULES_DIR"
    
    print_success "🎉 ベストプラクティスリンクが完了しました！"
    print_info "変更されたファイル:"
    print_info "  - CLAUDE.md: ベストプラクティス参照を追加"
    if [[ -f "./README.md" ]]; then
        print_info "  - README.md: dotrulesバッジを追加（該当する場合）"
    fi
}

# スクリプトの実行
main "$@"