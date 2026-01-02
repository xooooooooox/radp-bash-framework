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
Version:        0.1.0
Release:        1%{?dist}
Summary:        Modular Bash framework with structured context

License:        MIT
URL:            https://github.com/xooooooooox/radp-bash-framework
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       coreutils

%global radp_root %{_datadir}/radp-bash-framework

%description
radp-bash-framework is a modular Bash framework with structured context.

%prep
%setup -q -n %{name}

%build
# nothing to build

%install
rm -rf %{buildroot}

# install framework "root" that keeps bin/ and framework/ as siblings
mkdir -p %{buildroot}%{radp_root}
cp -a src/main/shell/bin %{buildroot}%{radp_root}/
cp -a src/main/shell/framework %{buildroot}%{radp_root}/

# ensure executables
chmod 0755 %{buildroot}%{radp_root}/bin/radp-bf
find %{buildroot}%{radp_root}/framework -type f -name "*.sh" -exec chmod 0755 {} \;

# user-facing commands
mkdir -p %{buildroot}%{_bindir}
ln -s %{radp_root}/bin/radp-bf %{buildroot}%{_bindir}/radp-bf
ln -s %{radp_root}/bin/radp-bf %{buildroot}%{_bindir}/radp-bash-framework

%files
%license LICENSE
%doc README.md
%{_bindir}/radp-bf
%{_bindir}/radp-bash-framework
%{radp_root}

%changelog
* Thu Jan 01 2026 xooooooooox <xozoz.sos@gmail.com> - 0.1.0-2
- Initial OBS RPM package
