# VPN Conflict Analysis - ShadowsocksX-NG and Cisco AnyConnect

## Analysis Completed
This document summarizes findings from analyzing how ShadowsocksX-NG handles proxy configuration and why VPNs like Cisco AnyConnect cause conflicts.

## Key Files Analyzed
- proxy_conf_helper/main.m - System proxy configuration
- ShadowsocksX-NG/PACUtils.swift - PAC file generation
- ShadowsocksX-NG/ProxyConfHelper.m - Proxy configuration interface
- ShadowsocksX-NG/ProxyCoordinator.swift - Proxy mode switching
- ShadowsocksX-NG/ProxyInterfacesViewCtrl.swift - Network service management
- ShadowsocksX-NG/ProxyConfTool.m - Network service detection

## Key Findings
1. Network service enumeration (Wi-Fi, Ethernet, AirPort)
2. Proxy exceptions configured at system level
3. PAC files define routing rules
4. No VPN detection mechanism (noted in roadmap)
5. VPN adds virtual network interface that gets proxy routing