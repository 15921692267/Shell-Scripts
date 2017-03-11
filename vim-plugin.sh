#!/bin/bash
# Description: Vim Python development intergrated environment
# Install Vundle (Vim management plugin) 

str_color(){
	if [ $1 == "green" ]; then
		echo -e "\033[32;40m$2 \033[0m"
	elif [ $1 == "red" ];then
		echo -e "\033[31;40m$2 \033[0m"
	else
		echo "str_color function quote failure!"
	fi
}

for pkg in git vim python-dev cmake; do
	yes=$(dpkg -l |awk '$2=="'$pkg'"{print "yes"}')
	[ ${yes:-no} != "yes" ] && pkg_array+=($pkg)
done
[ "${#pkg_array[*]}" -ne 0 ] && sudo apt-get install ${pkg_array[*]} -y

plugin_dir=~/.vim/bundle

git clone https://github.com/VundleVim/Vundle.vim.git $plugin_dir/Vundle.vim
[ -d ~/.vim/bundle/Vundle.vim ] && str_color green "Vundle Installation successful."

# Configure vimrc
config_file=~/.vimrc
touch $config_file

cat << EOF > $config_file
set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

"Plugin 'VundleVim/Vundle.vim'
"命令行管理插件
Plugin 'gmarik/Vundle.vim'
"语法检查,只能保存或打开时检查
Plugin 'scrooloose/syntastic'  
"语法检查，弥补syntastic不足，能buffer中动态检查语法
Bundle 'kevinw/pyflakes-vim'
"侧栏树形目录
Bundle 'scrooloose/nerdtree'  
"Python语法高亮
Bundle 'python-syntax'  
"代码高亮主题1
Bundle 'tomasr/molokai'
"代码高亮主题2
"Bundle 'Glench/Vim-Jinja2-Syntax'  
"代码高亮主题3
"Bundle 'altercation/vim-colors-solarized'
"自动补全
Bundle 'Valloric/YouCompleteMe'  
"输入引号、括号时自动补全
Bundle 'Raimondi/delimitMate'
"快速插入自定义代码段
Bundle 'SirVer/ultisnips'
Bundle 'honza/vim-snippets'
"批量注释
Bundle 'scrooloose/nerdcommenter'
"多光标批量操作，可用于批量修改某字符串
Bundle 'vim-multiple-cursors'
"状态栏增强
Bundle "bling/vim-airline"
"自动保存
Bundle 'vim-scripts/vim-auto-save'     

call vundle#end()
filetype plugin indent on

"-----------------插件管理-------------------
"开启自动保存
let g:auto_save = 1   
"开启pyflakes-vim
let g:pyflakes_use_quickfix = 0
"启动molokai
let g:molokai_original = 1
"侧栏树形目录快捷键
map <C-f> :NERDTree <CR>
"vim启动自动开启目录树
"au VimEnter * NERDTree
"触发代码片段功能
let g:UltisnipsExpandTrigger="<tab>"
"------------------------------------

"基本配置
"------------------------------------
"检查文件类型
filetype on 
"针对不用的文件类型采取不同的缩进格式
filetype indent on
"允许插件
filetype plugin on
"启动自动补全
filetype plugin indent on
"非兼容vi模式，避免以前版的一些缺陷
set nocompatible
"文件修改自动载入
"set autoread
"为所有模式启用鼠标
set mouse=a
"----------------搜索--------------------
"高亮显示搜索出的字符串
set hlsearch
"搜索时忽略大小写
set ignorecase
"随着键入即使搜索
set incsearch
"有一个或以上大写字母时扔大小写敏感
set smartcase
"----------------缩进--------------------
"智能缩进
set smartindent
"自动缩进
set autoindent
"设置tab键的宽度（等于空格个数）
set tabstop=4
"自动对齐的空格数
set shiftwidth=4
"按退格键时可以一次删除4个空格
set softtabstop=4
"-----------------编码-------------------
set encoding=utf-8
"自动判断编码时，以此尝试以下编码
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
"-----------------语法-------------------
"打开语法高亮
syntax enable
syntax on

EOF

vim -u ~/.vimrc +BundleInstall! +BundleClean +qall
str_color green "Recompile the YouCompleteMe..."
cd $plugin_dir/YouCompleteMe && bash install.sh --clang-completer
[ $? -eq 0 ] && str_color green "Recompile the YouCompleteMe successful."

