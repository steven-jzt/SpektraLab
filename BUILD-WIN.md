# Windows 构建记录（本分支）

上游：`JamesQiu2005/SpektraLab`，分支 `Windows_Linux`，提交 `aaec952`（2026-11-03）。
本分支 `win-build` 只是把**已经验证过的构建方式与打包脚本**留在源码树里，渲染与界面逻辑未改。

## 本分支相对上游的改动

| 文件 | 改动 |
|---|---|
| `engine/setup-codecs.ps1` | libpng-1.6.59 的 SHA-256 换成 GitHub tag 归档的哈希（sourceforge 在本机只返回 HTML 页面）。**此改动已包含在第一个提交里**，未单独拆成补丁提交 |
| `packaging/` | 免管理员安装/卸载脚本（拷到 `%LOCALAPPDATA%`，建桌面与开始菜单快捷方式） |
| `docs/` | 使用说明、构建说明、对社区维护版的功能对比分析 |
| `BUILD-WIN.md` | 本文件 |

未纳入本分支的目录：`modern_UI/`（macOS SwiftUI 界面）、`screenshots/`（宣传图）。
两者与 Windows 构建无关，上游仓库里完整保留。

## 构建环境（全部装在用户目录，无需管理员）

| 组件 | 版本 | 来源 |
|---|---|---|
| MinGW-w64 | GCC 16.2.0 | w64devkit 2.11 |
| CMake / Ninja | 4.4.4 / 1.13.0 | pip |
| glslangValidator | 16.6.0 | 从源码编译（49 个 Vulkan kernel 需要） |
| Rust | 1.99.1 `x86_64-pc-windows-gnu` | rustup |
| Node / npm | 24.15 / 11.x | — |
| Meson | 1.12.1 | pip（GLib 用） |

## 构建步骤

```powershell
# 依赖（LibRaw / 导出编解码 / 输入编解码 / lens）
python engine/setup-libraw.ps1 -DependencyDirectory <deps>
python engine/setup-codecs.ps1 -DependencyDirectory <deps>/export-codecs
python engine/setup-input-codecs.py --sources <s> --build <b> --install <i> --generator "MinGW Makefiles"
python engine/setup-lens-codecs.py --sources <s> --build <b> --install <i> --generator Ninja

# 引擎 + 宿主
cmake -S . -B build/host -G Ninja -DCMAKE_BUILD_TYPE=Release `
  -DSPEKTRALAB_REQUIRE_VULKAN=ON -DSPEKTRALAB_BUILD_NATIVE_RAW=ON `
  -DSPEKTRALAB_BUILD_HOST=ON -DSPEKTRALAB_STATIC_RUNTIME=ON ...
cmake --build build/host -j 8
ctest --test-dir build/host

# 外壳
cd desktop; npm install; npm run tauri build -- --no-bundle
```

## 依赖踩坑（重要）

`setup-lens-codecs.py` 默认从 `wrapdb.mesonbuild.org` 取 zlib / pcre2 的补丁包，
该域名在某些网络下完全不可达。当时的手工替代方案：

1. zlib 1.3.1、pcre2 10.44 用 CMake 自行构建到同一前缀
2. libffi 用 git 从 `gitlab.freedesktop.org/gstreamer/meson-ports/libffi` 取（pin `83d0cfd`）
3. `proxy-libintl` 放到 `glib-*/subprojects/proxy-libintl`（pin `33934de`）
4. 额外补一个 `libz.a`（zlib 的 CMake 只产出 `libzlibstatic.a`）

另外 GitHub 的 git 传输在这台机器上需要 `-c http.sslBackend=openssl`，
否则报 `schannel: SEC_E_NO_CREDENTIALS`。

## 验证结果

| 项 | 结果 |
|---|---|
| CTest（引擎 + 宿主） | 45 / 45 |
| 前端 typecheck / lint | 0 错 |
| 前端 vitest | 423 通过（1 skipped） |
| 运行 | Intel Arc，Vulkan 初始化 101 ms |
| 端到端 | 单实例转发打开 PNG；外部 CLI 改参后窗口同秒刷新 |

未验证：真实 RAW 全链路出图（片边 + 日期背印 + 导出）、NVIDIA/AMD 显卡、广色域多屏。

## 已知限制

- `contrast_mask` 被引擎拒绝（macOS 版同样隐藏）
- Nikon HE / HE* 不支持
- 未签名 exe，首次运行需过 SmartScreen
- 不要放在带 `Everyone:(DENY)(DC)` ACL 的目录下，WebView2 会建不了环境
