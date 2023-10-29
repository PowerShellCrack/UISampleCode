$ErrorActionPreference = "Stop"
#Load the Windows Presentation Format assemblies
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore') | out-null
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework') | out-null

#Embed xaml code in script
[string]$XAML = @"
<Window x:Class="WpfApp2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp2"
        mc:Ignorable="d"
        Title="PowerShell on Crack App1" Height="450" Width="800" WindowStyle="None" ResizeMode="NoResize">
        <Window.Resources>
            <ResourceDictionary>
                <Style TargetType="{x:Type Button}">
                    <Setter Property="Background" Value="#FF1D3245" />
                    <Setter Property="Foreground" Value="#FFE8EDF9" />
                    <Setter Property="FontSize" Value="15" />
                    <Setter Property="SnapsToDevicePixels" Value="True" />
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="Button" >
                                <Border Name="border"
                                        BorderThickness="1"
                                        Padding="4,2"
                                        BorderBrush="#336891"
                                        CornerRadius="1"
                                        Background="#0078d7">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.TextAlignment="Center"/>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="border" Property="BorderBrush" Value="#FFE8EDF9" />
                                    </Trigger>
                                    <Trigger Property="IsPressed" Value="True">
                                        <Setter TargetName="border" Property="BorderBrush" Value="#FF1D3245" />
                                        <Setter Property="Button.Foreground" Value="#FF1D3245" />
                                        <Setter Property="Effect">
                                            <Setter.Value>
                                                <DropShadowEffect ShadowDepth="0" Color="#FF1D3245" Opacity="1" BlurRadius="10"/>
                                            </Setter.Value>
                                        </Setter>
                                    </Trigger>
                                    <Trigger Property="IsEnabled" Value="False">
                                        <Setter TargetName="border" Property="BorderBrush" Value="#336891" />
                                        <Setter Property="Button.Foreground" Value="#336891" />
                                    </Trigger>
                                    <Trigger Property="IsFocused" Value="False">
                                        <Setter TargetName="border" Property="BorderBrush" Value="#336891" />
                                        <Setter Property="Button.Background" Value="#336891" />
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </ResourceDictionary>
        </Window.Resources>
    <Grid>
        <Label x:Name="lblHeader" Content="Powershell on Crack UI example" HorizontalAlignment="Left" Margin="35,10,0,0" VerticalAlignment="Top" Width="310"/>
        <ComboBox x:Name="cmbSelection" HorizontalAlignment="Left" Margin="90,125,0,0" VerticalAlignment="Top" Width="328"/>
        <Button x:Name="btnStart" Content="Start" HorizontalAlignment="Left" Margin="497,337,0,0" VerticalAlignment="Top" Height="54" Width="120"/>
        <Button x:Name="btnExit" Content="Exit" HorizontalAlignment="Left" Margin="633,337,0,0" VerticalAlignment="Top" Height="54" Width="113"/>
        <CheckBox x:Name="chkEnable" Content="Enable" HorizontalAlignment="Left" Margin="90,176,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name="txtName" HorizontalAlignment="Left" Margin="90,92,0,0" TextWrapping="Wrap" Text="TextBox" VerticalAlignment="Top" Width="223"/>

    </Grid>
</Window>
"@
 
#replace some default attributes to support PowerShell's xml node reader
[string]$XAML = $XAML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
#convert to XML
[xml]$UIXML = $XAML
#Read the XML
$reader=(New-Object System.Xml.XmlNodeReader $UIXML)
#Load the xml reader into a form as a UI
try{
    $UI=[Windows.Markup.XAMLReader]::Load( $reader )
}
catch{
    Write-Error $_.Exception.HResult
}
 
#take the UI elements and make them variables
$UIXML.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name "$($_.Name)" -Value $UI.FindName($_.Name)}


#=======================================
# EVENTS AND INTERACTIVE ELEMENTS

#adds the ability to drag windowsless screen around
$eventHandler_LeftButtonDown = [Windows.Input.MouseButtonEventHandler]{$this.DragMove()}
$UI.Add_MouseLeftButtonDown($eventHandler_LeftButtonDown)

#disables the Windows X
$UI.Add_Closing({$_.Cancel = $true})

#update the title of the window
$UI.Title = "Application selector"
#update the label of the window and make it bigger
$lblHeader.Content = "Select the application to install"
$lblHeader.FontSize = 20

#add user name to the textbox
$txtName.Text = "newUser"

#add items to the combobox
@("Adobe Reader","Mozilla FireFox","Power Bi","Google Chrome") | 
        ForEach-Object {$cmbSelection.Items.Add($_) | Out-Null}

#update the label of the checkbox
$chkEnable.Content = "Reboot (if needed)"

#hide the checkbox until an item is selected
$chkEnable.Visibility = "Hidden"
#disable the start button until an item is selected
$btnStart.IsEnabled = $false
#create event for combobox selection
$cmbSelection.Add_SelectionChanged({
    #reset the checkbox on each selection
    $chkEnable.IsChecked = $false

    switch($cmbSelection.SelectedItem){
        "Adobe Reader" {$chkEnable.Visibility = "Visible"}
        "Mozilla FireFox" {$chkEnable.Visibility = "Hidden"}
        "Power Bi" {$chkEnable.Visibility = "Visible"}
        "Google Chrome" {$chkEnable.Visibility = "Hidden"}
    }

    If($null -ne $cmbSelection.SelectedItem){
        $btnStart.IsEnabled = $true
    }
})


#start action for button
$btnStart.Add_Click({
    $btnStart.IsEnabled = $false
    $btnStart.Content = "Installing..."
    
    
    #get the application path and arguments from the combobox
    switch($cmbSelection.SelectedItem){
        "Adobe Reader" {$appPath = ".\apps\AdobeReader.exe";$args="/sAll /rs /msi EULA_ACCEPT=YES"}
        "Mozilla FireFox" {$appPath = ".\apps\Firefox.exe";$args="/s"}
        "Power Bi" {$appPath = ".\apps\PowerBi.msi";$args="/qn /norestart"}
        "Google Chrome" {$appPath = ".\apps\Chrome.exe";$args="/silent /install"}
    }

    #do install based on extension
    If($appPath.Split(".")[-1] -eq "exe"){
        Write-Host "Start-Process -FilePath $appPath -ArgumentList `"$args`" -Wait"
    }else{
        $args = "/i $appPath $args"
        Write-Host "Start-Process -FilePath msiexec.exe -ArgumentList `"$args`" -Wait"
    }

    #wait 60 seconds for the install to finish
    $counter = 0
    while ($counter++ -lt 10) {
        Start-Sleep -Seconds 1
        Write-Host '.' -NoNewline
    }

    If($chkEnable.IsChecked){
        Restart-Computer -Force -WhatIf
        Write-Host "Restart-Computer -Force"
    }
    else{
        Write-Host "No reboot needed"
    }

    #reset the combobox and remove the previous selected item
    $cmbSelection.Items.Remove($cmbSelection.SelectedItem)
    $cmbSelection.SelectedItem = $null
    $cmbSelection.Items.Refresh()
    $btnStart.Content = "Start"
    
})

#exit action for button
$btnExit.Add_Click({
    #then add to all closeable controls like exit button:
    $UI.Add_Closing({$_.Cancel = $false})
    $UI.Close()
})
#=======================================
#PRESENT UI
$UI.ShowDialog()