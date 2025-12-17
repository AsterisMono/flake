# Noa's Nix Flake (NixOS + nix-darwin + home-manager)

[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2FAsterisMono%2Fflake%3Fbranch%3Dmain)](https://garnix.io/repo/AsterisMono/flake)

这是一个以 flake 为入口的个人配置仓库：同时管理 NixOS 主机、macOS（nix-darwin）以及跨平台的 home-manager 配置，并提供一些可复用的模块、overlay、packages、templates 与安装/部署脚本。

本仓库包含大量个人偏好与主机相关设置（例如用户、密钥、网络、服务端口等）。如果你打算 fork 或作为依赖消费，建议先从 `nixosConfigurations/` / `darwinModules/` / `homeModules/` 的结构理解，再按需取用模块。

## 你能在这里找到什么

- **多主机管理**：`nixosConfigurations/`（每台 NixOS 主机一个文件），`darwinConfigurations`（flake 内列表管理）。
- **可复用模块**：
  - `nixosModules/`：角色（desktop/server）、硬件、磁盘布局（disko）、GUI 套件（GNOME/Plasma）、服务（Tailscale、DN42、Proxy、Docker 等）。
  - `darwinModules/`：nix-darwin 系统设置、Homebrew、代理（mihomo）等。
  - `homeModules/`：home-manager 基础层 + Linux 桌面应用组合（含 Stylix、VSCode、Firefox、fcitx5 等）。
- **Secrets 管理**：`secrets/` 使用 `sops` + `age` 加密；模块通过 `sops-nix` 引用。
- **自定义输出**：`packages/`、`overlays/`、`templates/`、以及用于离线安装的 `offlineInstaller` ISO 输出。

## 目录结构速览

- `flake.nix`：flake 输出定义（modules、configs、packages、checks、devShell、deploy 等）
- `nixosConfigurations/`：每台 NixOS 主机的顶层配置（与 `hardwares/<host>.nix` 对应）
- `hardwares/`：硬件相关配置（部分来自 `nixos-generate-config` 或手工维护）
- `nixosModules/` / `darwinModules/` / `homeModules/`：可复用模块
- `packages/`：自定义包（通过 flake `packages` 输出）
- `overlays/`：自定义 overlay（含 `pkgs.flakePackages`、扩展 `lib` 等）
- `templates/`：`nix flake init -t` 可用模板
- `scripts/`：辅助脚本（例如救援环境下生成网络配置片段）
- `assets/`：壁纸、DN42 ROA 配置、设备固件等静态资源
- `secrets/`：SOPS 加密的敏感信息（务必保持加密状态）

## 当前主机一览

NixOS（`nixosConfigurations/`）：

- `azura`：桌面（Plasma + Stylix + Flatpak + Tailscale + Docker + Proxy），`diskLayouts.btrfs`
- `anemone`：服务器（Headscale + Headplane + Caddy），`diskLayouts.gpt-bios-compat`
- `ivy`：服务器/路由（NanoPi R2S，aarch64；Tailscale + DN42 + Prometheus exporters + ddclient）

macOS（nix-darwin，flake 内配置）：

- `Fervorine`：aarch64-darwin（系统偏好设置、Homebrew、Tailscale、mihomo 代理等）

## 快速开始（开发/检查）

前置：已安装 Nix，并启用 `nix-command` + `flakes`。

- 进入开发环境：`nix develop`
- （可选）配合 direnv：`direnv allow`
- 运行 flake 检查（含 nixfmt 与 statix）：`nix flake check --print-build-logs`

本仓库在 devShell 中提供：`nixfmt-rfc-style`、`statix`、`just`、`deploy-rs`、`sops`、`ssh-to-age`、`nh` 等常用工具。

## 常用命令（Justfile）

NixOS 本机（需要 sudo）：

- 构建：`just build`
- 切换部署：`just deploy`
- 写入引导（不切换）：`just boot`
- 预演：`just dryrun`
- 查看系统 profile 历史：`just history`
- GC：`just gc`

macOS（nix-darwin）：

- 初次/切换：`just darwin-bootstrap`
- 日常切换（nh）：`just darwin-deploy`

远程安装 / 装机（结合 nixos-anywhere / disko）：

- 远程安装：`just install <hostname> <target>`
- 裸机引导安装：`just bootstrap <hostname> <disk>`
- 生成硬件配置：`just generate-hardware-config <hostname> <target>`（写入 `hardwares/<hostname>.nix`）

deploy-rs（可选）：

- 部署全部节点：`just rdeploy`
- 部署单机：`just rdeploy-host <hostname>`

## 模块与约定

### 模块输出（flake）

flake 暴露以下输出，便于复用：

- `nixosModules` / `darwinModules` / `homeModules`
- `overlays`
- `packages.<system>.*`
- `templates.*`

在本仓库里，目录型模块通常以 `package.nix` 作为入口（例如 `nixosModules/roles/desktop/package.nix`），并在主机配置里以 `roles.desktop` 的形式被引用；同时也存在“参数化模块”（例如 `services.prometheus-blackbox` 需要传入 `listenAddress`）。

### 作为依赖消费（可选）

如果你想复用这里的模块/overlay/packages，可以在自己的 `flake.nix` 中添加输入并引用输出，例如：

```nix
{
  inputs.noa-flake.url = "github:AsterisMono/flake";
  outputs = { self, noa-flake, ... }: {
    nixosConfigurations.myhost = /* ... */ {
      modules = [
        noa-flake.nixosModules.services.tailscale
        noa-flake.nixosModules.roles.desktop
      ];
    };
  };
}
```

### 自定义选项（noa.*）

仓库内定义了一些命名空间选项（非穷尽）：

- `noa.nix.enableMirrorSubstituter`：启用国内镜像 substituter（NixOS）
- `noa.homeManager.enable` / `noa.homeManager.modules`：NixOS 上集成 home-manager（见 `nixosModules/users/cmiki.nix`）
- `noa.proxy.tunMode` / `noa.proxy.port`：mihomo 代理与系统代理设置（NixOS）
- `noa.tailscale.*`：Tailscale 自动 up 参数（ssh/tags/routes 等）
- `noa.docker.*`：Docker registry mirror、Watchtower
- `noa.dn42.*`：DN42（WireGuard + bird2）相关参数

## Secrets（SOPS + age）

`secrets/` 下的文件使用 SOPS 加密，规则在 `.sops.yaml` 中：

- `secrets/home.yaml` 通常只对个人密钥（`noa`）加密
- `secrets/<host>.{yaml,json,...}` 可以同时对个人与主机密钥加密（便于主机解密自身所需 secrets）

约定的 age key 路径：

- `~/.config/sops/age/keys.txt`

常用操作：

- 编辑 secrets：`sops secrets/<file>`
- 更新收件人：`just updatekeys`
- 从远端主机 SSH host key 生成 age recipient：`just scan-age-key <target>`

注意：不要提交解密后的 secrets；仓库的 `.gitignore` 已忽略常见的解密产物与临时密钥文件。

## 离线安装 ISO（offlineInstaller）

每个 `nixosConfigurations.<host>` 还会额外暴露一个 `offlineInstaller`（最小安装镜像），其特性是把本 flake 以及 flake.lock 里的输入依赖预先放入 ISO 的 store 中，便于弱网/离线安装时减少下载。

注意：当前 `offlineInstaller` 固定构建为 `x86_64-linux` 安装介质（见 `lib/withOfflineInstaller.nix`）。

示例：

- 构建 ISO：`nix build .#nixosConfigurations.<host>.offlineInstaller`

## CI / 部署自动化

- `garnix.yaml`：Garnix 构建配置（包括 `nixosConfigurations.*`）
- `.github/workflows/deploy.yml`：手动触发的 GitHub Actions workflow，会在 self-hosted runner 上对所有主机执行 `deploy-rs`（runner 配置见 `nixosModules/services/irrigation-runner.nix`）

## Templates

`templates/` 目录下提供 flake 模板：

- `devShell`：基础开发壳模板（含 `.envrc`）
- `node`：Node/TypeScript 项目模板

在本仓库内使用：`nix flake init -t .#devShell`（或 `.#node`）。

## License

见 `LICENSE`。
