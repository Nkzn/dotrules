#!/bin/bash

# dotrules submodule セットアップスクリプト
# dotrulesをgit submoduleとして追加し、プロジェクトに統合します

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

# Gitリポジトリかどうかをチェック
check_git_repository() {
    if [[ ! -d ".git" ]]; then
        print_error "このディレクトリはGitリポジトリではありません"
        print_info "まず 'git init' を実行してください"
        exit 1
    fi
}

# dotrulesをsubmoduleとして追加
setup_dotrules_submodule() {
    local dotrules_url="https://github.com/Nkzn/dotrules.git"
    local submodule_path="dotrules"
    
    if [[ -d "$submodule_path" ]]; then
        print_warning "dotrulesディレクトリが既に存在します"
        if [[ -f ".gitmodules" ]] && grep -q "$submodule_path" .gitmodules; then
            print_info "既にsubmoduleとして登録されています"
            return 0
        else
            print_error "dotrulesディレクトリが存在しますが、submoduleではありません"
            print_info "手動で削除してから再実行してください: rm -rf $submodule_path"
            exit 1
        fi
    fi
    
    print_info "dotrulesをsubmoduleとして追加中..."
    
    # submoduleを追加
    git submodule add "$dotrules_url" "$submodule_path"
    
    # 初期化と更新
    git submodule update --init --recursive
    
    print_success "dotrulesをsubmoduleとして追加しました"
    
    # .gitmodulesファイルをコミット
    if git status --porcelain | grep -q ".gitmodules"; then
        git add .gitmodules "$submodule_path"
        git commit -m "feat: dotrulesをsubmoduleとして追加

- ベストプラクティス・テンプレート集を統合
- チーム全体での開発標準化を実現"
        print_success ".gitmodulesをコミットしました"
    fi
}

# CLAUDE.mdにsubmodule用のパスを設定
setup_claude_md_for_submodule() {
    local template_file="dotrules/templates/CLAUDE.md.template"
    local target_file="./CLAUDE.md"
    
    if [[ ! -f "$template_file" ]]; then
        print_error "dotrulesのテンプレートファイルが見つかりません"
        print_info "submoduleが正しく初期化されているか確認してください"
        exit 1
    fi
    
    if [[ -f "$target_file" ]]; then
        print_warning "CLAUDE.mdが既に存在します"
        read -p "上書きしますか? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "CLAUDE.mdの作成をスキップしました"
            return
        fi
        
        # バックアップを作成
        cp "$target_file" "${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "既存のCLAUDE.mdをバックアップしました"
    fi
    
    # submodule用のパスに置換してテンプレートを適用
    sed "s|PATH_TO_DOTRULES|dotrules|g" "$template_file" > "$target_file"
    
    print_success "CLAUDE.mdを作成しました（submodule参照）"
}

# 設定ファイルのセットアップ
setup_config_files_from_submodule() {
    local templates_dir="dotrules/templates"
    
    print_info "設定ファイルテンプレートをセットアップ中..."
    
    # TypeScriptプロジェクトの場合
    if [[ -f "package.json" ]] && grep -q "typescript" package.json 2>/dev/null; then
        copy_template_if_not_exists "$templates_dir/tsconfig.json.template" "./tsconfig.json"
        copy_template_if_not_exists "$templates_dir/vitest.config.ts.template" "./vitest.config.ts"
        copy_template_if_not_exists "$templates_dir/vitest.integration.config.ts.template" "./vitest.integration.config.ts"
        copy_template_if_not_exists "$templates_dir/vitest.setup.ts.template" "./vitest.setup.ts"
        copy_template_if_not_exists "$templates_dir/vitest.integration.setup.ts.template" "./vitest.integration.setup.ts"
    fi
    
    # package.jsonスニペットの参照を表示
    if [[ -f "package.json" ]]; then
        print_info "package.jsonの推奨スクリプトについては以下を参照してください:"
        print_info "  - ファイル: $templates_dir/package.json.snippets"
    fi
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

# 使用方法の表示
show_usage() {
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "説明:"
    echo "  dotrulesをgit submoduleとして追加し、プロジェクトに統合します"
    echo ""
    echo "オプション:"
    echo "  -h, --help     このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0              # dotrulesをsubmoduleとして追加"
    echo ""
    echo "事前要件:"
    echo "  - Gitリポジトリ内で実行"
    echo "  - インターネット接続（GitHub接続用）"
}

# submodule更新の案内
show_update_instructions() {
    print_info ""
    print_info "📋 submodule管理コマンド:"
    print_info ""
    print_info "最新版に更新:"
    print_info "  git submodule update --remote dotrules"
    print_info "  git add dotrules && git commit -m 'chore: dotrulesを最新版に更新'"
    print_info ""
    print_info "特定バージョンに固定:"
    print_info "  cd dotrules && git checkout v1.2.3 && cd .."
    print_info "  git add dotrules && git commit -m 'chore: dotrules v1.2.3に固定'"
    print_info ""
    print_info "チームメンバーの初期セットアップ:"
    print_info "  git clone --recursive <repository-url>"
    print_info "  # または"
    print_info "  git clone <repository-url> && git submodule update --init --recursive"
}

# メイン処理
main() {
    # コマンドライン引数の解析
    while [[ $# -gt 0 ]]; do
        case $1 in
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
    
    print_info "dotrules submoduleセットアップを開始します..."
    
    # 事前チェック
    check_git_repository
    
    # dotrulesをsubmoduleとして追加
    setup_dotrules_submodule
    
    # CLAUDE.mdのセットアップ
    setup_claude_md_for_submodule
    
    # 設定ファイルのセットアップ
    setup_config_files_from_submodule
    
    print_success "🎉 dotrulesのsubmodule統合が完了しました！"
    
    # 管理方法の案内
    show_update_instructions
    
    print_info ""
    print_info "次のステップ:"
    print_info "  1. CLAUDE.mdを編集してプロジェクト固有の情報を追加"
    print_info "  2. 設定ファイルをプロジェクトに合わせて調整"
    print_info "  3. チームメンバーに submodule 使用方法を共有"
}

# スクリプトの実行
main "$@"