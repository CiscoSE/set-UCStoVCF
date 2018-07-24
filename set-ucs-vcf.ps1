<#
.NOTES
Copyright (c) 2018 Cisco and/or its affiliates.

This software is licensed to you under the terms of the Cisco Sample
Code License, Version 1.0 (the "License"). You may obtain a copy of the
License at

               https://developer.cisco.com/docs/licenses

All use of the material herein must be in accordance with the terms of
the License. All rights not expressly granted by the License are
reserved. Unless required by applicable law or agreed to separately in
writing, software distributed under the License is distributed on an "AS
IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied.
.DESCRIPTION

Script configures UCS C240 M5 servers to comply with requirements for 
vCloud Foundation. These requirements are not validated by Cisco. All
settings should be validated through VMWare before running this script.

This script is design to fail by default. You must use the -Execute switch
to run this script.

This script assumes you are already connected to the server you want to
modify. Please see the connect-imc commandlet for connecting to a server.

#>
[cmdletbinding()]
param(
    [switch]$Execute = $false
)

# Failsafe switch prevents this from running by accident. 
# This script changes things, and you might not like the results.
if ($execute -eq $false){
    Write-Host "Script is designed not to run with out the -Execute Switch."
    Write-Host "Script will Exit"
    exit
}

#Server Status - Server must be on, or we cannot configure the VIC.
$ServerStatus = get-imcServer
if ($ServerStatus.OperPower -ne "on"){
    set-imcserver -RackUnit 1 -AdminPower 'up' # Turn the power on
    sleep 30                                   # We need time to let the system come up
}

#Reset VIC Adaptors to Factory Default
Get-ImcAdaptorUnit | 
    Set-ImcAdaptorUnit -AdminState adaptor-reset-default -force

#Reset BIOS Settings to Factory Default
Set-ImcBiosSettings -ResetToPlatformDefault -force


sleep 5 # We need this to settle a few seconds before we make the next change.

#Set PXE on all adaptors
Get-ImcAdaptorHostEthIf | 
    %{$_ | Set-ImcAdaptorHostEthIf -PxeBoot enabled -force}

$biosSettings  = Get-ImcRackUnit -ServerId "1" | Get-ImcBiosUnit | Get-ImcBiosSettings 

Start-ImcTransaction
#Specifically required by VCF
$mo_27  = $biosSettings | Get-ImcBiosNUMA | Set-ImcBiosNUMA -VpNUMAOptimized "enabled"
$mo_19  = $biosSettings | Get-ImcBiosVfIntelVirtualizationTechnology | Set-ImcBiosVfIntelVirtualizationTechnology -VpIntelVirtualizationTechnology "enabled"
$mo_39  = $biosSettings | Get-ImcBiosVfSataModeSelect | Set-ImcBiosVfSataModeSelect -VpSataModeSelect AHCI
#$mo_36  = $biosSettings | Get-ImcBiosVfPSata | Set-ImcBiosVfPSata -VpPSata AHCI

#Additional Settings Recommended by Cisco Performance Tuning Guide
$mo_8  = $biosSettings | Get-ImcBiosVfCPUPerformance | Set-ImcBiosVfCPUPerformance -VpCPUPerformance enterprise
$mo_20  = $biosSettings | Get-ImcBiosIntelDirectedIO | Set-ImcBiosIntelDirectedIO -VpIntelVTDATSSupport "enabled" -VpIntelVTDCoherencySupport "disabled" -VpIntelVTForDirectedIO "enabled"
$mo_10  = $biosSettings | Get-ImcBiosEnhancedIntelSpeedStep | Set-ImcBiosEnhancedIntelSpeedStep -VpEnhancedIntelSpeedStepTech "enabled"
$mo_17  = $biosSettings | Get-ImcBiosHyperThreading | Set-ImcBiosHyperThreading -VpIntelHyperThreadingTech "enabled"
$mo_24  = $biosSettings | Get-ImcBiosVfLLCPrefetch | Set-ImcBiosVfLLCPrefetch -VpLLCPrefetch "Disabled"
$mo_18  = $biosSettings | Get-ImcBiosTurboBoost | Set-ImcBiosTurboBoost -VpIntelTurboBoostTech "enabled"
$mo_34  = $biosSettings | Get-ImcBiosVfProcessorC1E | Set-ImcBiosVfProcessorC1E -VpProcessorC1E "disabled"
$mo_35  = $biosSettings | Get-ImcBiosVfProcessorC6Report | Set-ImcBiosVfProcessorC6Report -VpProcessorC6Report "disabled"

#Things you might want
$mo_23  = $biosSettings | Get-ImcBiosVfLegacyUSBSupport | Set-ImcBiosVfLegacyUSBSupport -VpLegacyUSBSupport "disabled"
$mo_11  = $biosSettings | Get-ImcBiosExecuteDisabledBit | Set-ImcBiosExecuteDisabledBit -VpExecuteDisableBit "enabled"
$mo_25  = $biosSettings | Get-ImcBiosVfLOMPortOptionROM | Set-ImcBiosVfLOMPortOptionROM -VpLOMPort0State "Disabled" -VpLOMPort1State "Disabled" -VpLOMPortsAllState "Enabled"
$mo_44  = $biosSettings | Get-ImcBiosVfUSBPortsConfig | Set-ImcBiosVfUSBPortsConfig -VpUsbPortFront "Disabled" -VpUsbPortInternal "Disabled" -VpUsbPortKVM "Disabled" -VpUsbPortRear "Disabled" -VpUsbPortSDCard "Disabled"

#Settings I am not setting because they have been reset, and don't require special mention or attention
#$mo_1  = $biosSettings | Get-ImcBiosVfAdjacentCacheLinePrefetch | Set-ImcBiosVfAdjacentCacheLinePrefetch -VpAdjacentCacheLinePrefetch "enabled"
#$mo_2  = $biosSettings | Get-ImcBiosVfBootPerformanceMode | Set-ImcBiosVfBootPerformanceMode -VpBootPerformanceMode "Max Performance"
#$mo_3  = $biosSettings | Get-ImcBiosVfCDNEnable | Set-ImcBiosVfCDNEnable -VpCDNEnable "Enabled"
#$mo_4  = $biosSettings | Get-ImcBiosVfCmciEnable | Set-ImcBiosVfCmciEnable -VpCmciEnable "Enabled"
#$mo_5  = $biosSettings | Get-ImcBiosVfConsoleRedirection | Set-ImcBiosVfConsoleRedirection -VpBaudRate "115200" -VpConsoleRedirection "disabled" -VpFlowControl "none" -VpTerminalType "vt100"
#$mo_6  = $biosSettings | Get-ImcBiosVfCoreMultiProcessing | Set-ImcBiosVfCoreMultiProcessing -VpCoreMultiProcessing "all"
#$mo_9  = $biosSettings | Get-ImcBiosVfDCUPrefetch | Set-ImcBiosVfDCUPrefetch -VpIPPrefetch "enabled" -VpStreamerPrefetch "enabled"
#$mo_12  = $biosSettings | Get-ImcBiosVfExtendedAPIC | Set-ImcBiosVfExtendedAPIC -VpExtendedAPIC "Disabled"
#$mo_13  = $biosSettings | Get-ImcBiosVfFRB2Enable | Set-ImcBiosVfFRB2Enable -VpFRB2Enable "enabled"
#$mo_14  = $biosSettings | Get-ImcBiosVfHardwarePrefetch | Set-ImcBiosVfHardwarePrefetch -VpHardwarePrefetch "enabled"
#$mo_15  = $biosSettings | Get-ImcBiosVfHWPMEnable | Set-ImcBiosVfHWPMEnable -VpHWPMEnable "HWPM Native Mode"
#$mo_16  = $biosSettings | Get-ImcBiosVfIMCInterleave | Set-ImcBiosVfIMCInterleave -VpIMCInterleave "Auto"
#$mo_21  = $biosSettings | Get-ImcBiosVfIPV6PXE | Set-ImcBiosVfIPV6PXE -VpIPV6PXE "Disabled"
#$mo_22  = $biosSettings | Get-ImcBiosVfKTIPrefetch | Set-ImcBiosVfKTIPrefetch -VpKTIPrefetch "Enabled"
#$mo_26  = $biosSettings | Get-ImcBiosVfMemoryMappedIOAbove4GB | Set-ImcBiosVfMemoryMappedIOAbove4GB -VpMemoryMappedIOAbove4GB "enabled"
#$mo_28  = $biosSettings | Get-ImcBiosVfOSBootWatchdogTimer | Set-ImcBiosVfOSBootWatchdogTimer -VpOSBootWatchdogTimer "disabled"
#$mo_29  = $biosSettings | Get-ImcBiosOSBootWatchdogTimerTimeoutPolicy | Set-ImcBiosOSBootWatchdogTimerTimeoutPolicy -VpOSBootWatchdogTimerPolicy "power-off"
#$mo_30  = $biosSettings | Get-ImcBiosVfOSBootWatchdogTimerTimeout | Set-ImcBiosVfOSBootWatchdogTimerTimeout -VpOSBootWatchdogTimerTimeout "10-minutes"
#$mo_31  = $biosSettings | Get-ImcBiosVfPackageCStateLimit | Set-ImcBiosVfPackageCStateLimit -VpPackageCStateLimit "C0 C1 State"
#$mo_32  = $biosSettings | Get-ImcBiosVfPCISlotOptionROMEnable | Set-ImcBiosVfPCISlotOptionROMEnable -VpSlot1LinkSpeed "Auto" -VpSlot1State "Enabled" -VpSlot2LinkSpeed "Auto" -VpSlot2State "Enabled" -VpSlot3LinkSpeed "Auto" -VpSlot3State "Enabled" -VpSlot4LinkSpeed "Auto" -VpSlot4State "Enabled" -VpSlot5LinkSpeed "Auto" -VpSlot5State "Enabled" -VpSlot6LinkSpeed "Auto" -VpSlot6State "Enabled" -VpSlotFrontNvme1LinkSpeed "Auto" -VpSlotFrontNvme2LinkSpeed "Auto" -VpSlotMLOMLinkSpeed "Auto" -VpSlotMLOMState "Enabled" -VpSlotMRAIDLinkSpeed "Auto" -VpSlotMRAIDState "Enabled" -VpSlotN1State "Enabled" -VpSlotN2State "Enabled" -VpSlotRearNvme1LinkSpeed "Auto" -VpSlotRearNvme1State "Enabled" -VpSlotRearNvme2LinkSpeed "Auto" -VpSlotRearNvme2State "Enabled" -XtraProperty @{VpSlotSIOC2LinkSpeed=""; VpSlotIOEMezz1LinkSpeed=""; VpSlotIOEMezz1State=""; VpSlotIOENVMe1LinkSpeed=""; VpSlotIOENVMe2LinkSpeed=""; VpSlotSBMezz1State=""; VpSlotSIOC1LinkSpeed=""; VpIOESlot2State=""; VpSlotIOENVMe1State=""; VpSlotMLinkSpeed=""; VpSlotSIOC1State=""; VpIOESlot1State=""; VpSlotSBNVMe1LinkSpeed=""; VpSlotSBMezz2State=""; VpSlotSIOC2State=""; VpSlotSBNVMe1State=""; VpSlotIOESlot1LinkSpeed=""; VpSlotSBMezz1LinkSpeed=""; VpSlotSBMezz2LinkSpeed=""; VpSlotIOENVMe2State=""; VpSlotIOESlot2LinkSpeed=""; }
#$mo_33  = $biosSettings | Get-ImcBiosVfPowerOnPasswordSupport | Set-ImcBiosVfPowerOnPasswordSupport -VpPOPSupport "Disabled"
#
#
#$mo_37  = $biosSettings | Get-ImcBiosVfPStateCoordType | Set-ImcBiosVfPStateCoordType -VpPStateCoordType "HW ALL"
#$mo_38  = $biosSettings | Get-ImcBiosVfPwrPerfTuning | Set-ImcBiosVfPwrPerfTuning -VpPwrPerfTuning "os"
#$mo_40  = $biosSettings | Get-ImcBiosVfSelectMemoryRASConfiguration | Set-ImcBiosVfSelectMemoryRASConfiguration -VpSelectMemoryRASConfiguration "maximum-performance"
#$mo_41  = $biosSettings | Get-ImcBiosVfSubNumaClustering | Set-ImcBiosVfSubNumaClustering -VpSNC "Disabled"
#$mo_42  = $biosSettings | Get-ImcBiosVfTPMControl | Set-ImcBiosVfTPMControl -VpTPMControl "enabled"
#$mo_43  = $biosSettings | Get-ImcBiosVfTXTSupport | Set-ImcManagedObject -PropertyMap @{VpTXTSupport="Disabled"; }
#$mo_45  = $biosSettings | Get-ImcBiosVfVgaPriority | Set-ImcBiosVfVgaPriority -VpVgaPriority "Onboard"
#$mo_46  = $biosSettings | Get-ImcBiosVfWorkLoadConfig | Set-ImcBiosVfWorkLoadConfig -VpWorkLoadConfig "I/O Sensitive"
#$mo_47  = $biosSettings | Get-ImcBiosVfXPTPrefetch | Set-ImcBiosVfXPTPrefetch -VpXPTPrefetch "Disabled"
Complete-ImcTransaction -Force

#Set to Legacy boot mode. Default for M5 is UEFI

Get-ImcLsbootDevPrecision | Set-ImcLsbootDevPrecision -ConfiguredBootMode Legacy -RebootOnUpdate yes -force

# Remove any existing advanced boot order

get-ImcLsbootDevPrecision -Hierarchy | ?{$_.order} | Remove-ImcManagedObject -force

#SET new Boot order
Start-ImcTransaction
Get-ImcLsbootDevPrecision | Add-ImcLsbootPxe -Name PXE1 -Order 1 -Port 0 -Slot MLOM -State enabled -Subtype PXE
Get-ImcLsbootDevPrecision | Add-ImcLsbootPxe -Name PXE2 -Order 2 -Port 1 -Slot MLOM -State enabled -Subtype PXE
Get-ImcLsbootDevPrecision | Add-ImcLsbootPchStorage -Name ESXi -Order 3 -State enabled -Type PCHSTORAGE
Complete-ImcTransaction -force

# Set Password Policy to allow simple passwords.
# This change is not endorsed by CISCO, but is provided to assist where this is required.

Get-ImcAaaUserPolicy | Set-ImcAaaUserPolicy -UserPasswordPolicy disabled -force

# We are not setting the password in this file.

# Enable IPMI over Lan and set Key to 40 zeros
# Cisco does not recommend leaving this key with this setting.
Get-ImcCommIpmiLan | Set-ImcCommIpmiLan -AdminState enabled -Key 0000000000000000000000000000000000000000


