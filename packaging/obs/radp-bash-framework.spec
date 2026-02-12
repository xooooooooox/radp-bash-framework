#----------------------------------------------------------------------------------------------------------------------#
# 说明
# 1) Release 与 Version
# - Version: 表示源码版本号,通常与 Git tag/release 一致(比如 v0.0.2 -> 0.0.2)
# - Release: 标识在同一个 Version 下, 打包发布的第几次迭代(这里的迭代一般针对的是 spec 文件的修改)
# 2) changelog 编写规范
# - 第一行格式: * Day Mon DD YYYY Name <email> - Version-Release
# - 第二行以后: 用 -  列出变更点
#----------------------------------------------------------------------------------------------------------------------#

Name:           radp-bash-framework
Version:        0.7.21
Release:        1%{?dist}
Summary:        Modular Bash framework with structured context

License:        MIT
URL:            https://github.com/xooooooooox/radp-bash-framework
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       coreutils

%description
radp-bash-framework is a modular Bash framework with structured context.

%prep
%setup -q -n radp-bash-framework-%{version}

%build
# nothing to build

%install
rm -rf %{buildroot}

# install framework with standard CLI project structure
mkdir -p %{buildroot}%{_libdir}/radp-bash-framework/src/main/shell
cp -a bin %{buildroot}%{_libdir}/radp-bash-framework/
cp -a src/main/shell/commands %{buildroot}%{_libdir}/radp-bash-framework/src/main/shell/
cp -a src/main/shell/config %{buildroot}%{_libdir}/radp-bash-framework/src/main/shell/
cp -a src/main/shell/framework %{buildroot}%{_libdir}/radp-bash-framework/src/main/shell/

# ensure executables
chmod 0755 %{buildroot}%{_libdir}/radp-bash-framework/bin/radp-bf
find %{buildroot}%{_libdir}/radp-bash-framework/src/main/shell/framework -type f -name "*.sh" -exec chmod 0755 {} \;

# user-facing commands
mkdir -p %{buildroot}%{_bindir}
ln -s %{_libdir}/radp-bash-framework/bin/radp-bf %{buildroot}%{_bindir}/radp-bf
ln -s %{_libdir}/radp-bash-framework/bin/radp-bf %{buildroot}%{_bindir}/radp-bash-framework

# install shell completions (from root completions/ directory)
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
cp -a completions/radp-bf %{buildroot}%{_datadir}/bash-completion/completions/radp-bf
cp -a completions/_radp-bf %{buildroot}%{_datadir}/zsh/site-functions/_radp-bf

%post
echo "xooooooooox/radp-bash-framework" > %{_libdir}/radp-bash-framework/.install-repo
echo "rpm" > %{_libdir}/radp-bash-framework/.install-method
echo "v%{version}" > %{_libdir}/radp-bash-framework/.install-version

%files
%license LICENSE
%doc README.md
%{_bindir}/radp-bf
%{_bindir}/radp-bash-framework
%{_libdir}/radp-bash-framework/
%{_datadir}/bash-completion/completions/radp-bf
%{_datadir}/zsh/site-functions/_radp-bf

%changelog
* Thu Jan 07 2026 xooooooooox <xozoz.sos@gmail.com> - 0.1.1-1
- Initial RPM package
