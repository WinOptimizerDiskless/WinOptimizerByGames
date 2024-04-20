unit Optimizer;

interface
  uses
      windows, jvstringgrid,classes,JvDotNetControls;
   Type
      TOptimizer = record
       procedure SetRegString(const Key: string; const ValueName: string; const Data: string);
       function GetRegString(const Key: string; const ValueName: string; const DefaultValue: string): string;
       procedure SetRegStringAdmin(const Key: string; const ValueName: string; const Data: string);
       function GetRegStringAdmin(const Key: string; const ValueName: string; const DefaultValue: string): string;
       procedure SetRegDWORDAdmin(const Key: string; const ValueName: string; const Data: Integer);
       function GetRegDWORDAdmin(const Key: string; const ValueName: string; const DefaultValue: Integer): Integer;
       procedure WriteBinaryValue(const Key: string; const ValueName: string; Data: array of Byte; UseHKLM: Boolean);
       function IntOptToBool(opt: integer): boolean;
       procedure setOption(option: integer);
       procedure LoadStringGrid(grid: TJvDotNetCheckListBox);
       procedure LoadStringUWP(grid: TJvDotNetCheckListBox);
       procedure LoadOptions;
       procedure ReadAllAutoStartKeys(List: TStrings);
       procedure BackupAutoStartKeys(const BackupFilePath: string);
       procedure RestoreAutoStartKeys(const BackupFilePath: string);
       procedure DeleteRegistryValue(const KeyPath, ValueName: string);
       procedure OpenFolder(const FolderPath: string);
       procedure RegJump(const KeyPath: string);
       function ExtractExecutablePath(const CommandLine: string): string;
       procedure GetUWPApps(List: TStrings);
       procedure UninstallUWPApp(const PackageName: string);
       procedure DeleteRegistryKey(const KeyPath: string);
       function RunExecPid(ProgramName : String; Wait, hide: Boolean;minimize : boolean = false) : integer;
       function GetWindowsInfo: string;
      end;
    Type TOpenPolicyFunction = function(pMachineName: LPCWSTR; dwAccess: DWORD; var phPolicyHandle: THANDLE): DWORD; stdcall;
    type
      TPhotoViewerMode = (Restore, Disable);
    function OpenPolicy(pMachineName: LPCWSTR; dwAccess: DWORD; var phPolicyHandle: THandle): DWORD;
    function GetInstalledOfficeVersions: String;

    procedure SetClassicPhotoViewerMode(Mode: TPhotoViewerMode);
var
    winopt: TOptimizer;

implementation
         uses
            Registry,types,dialogs,shellapi,unit1,Vcl.WinXCtrls,sysutils,vcl.forms;
{ TOptimizer }
function TOptimizer.GetWindowsInfo: string;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion') then
    begin
      Result := Format('%s %s (Edition: %s, Version: %s)',
                       [Reg.ReadString('ProductName'),
                        Reg.ReadString('DisplayVersion'),
                        Reg.ReadString('EditionID'),
                        Reg.ReadString('CurrentVersion')]);
      Reg.CloseKey;
    end
    else
      Result := 'Unknown Windows';
  finally
    Reg.Free;
  end;
end;
function TOptimizer.ExtractExecutablePath(const CommandLine: string): string;
var
  QuoteIndex, SpaceIndex: Integer;
  FilePath: string;
begin
  // Найти путь к исполняемому файлу в строке командной строки
  QuoteIndex := Pos('"', CommandLine);
  if QuoteIndex > 0 then
  begin
    // Если путь начинается с кавычек, найти следующие кавычки
    QuoteIndex := Pos('"', CommandLine, QuoteIndex + 1);
    if QuoteIndex > 0 then
    begin
      // Извлечь подстроку между кавычек
      FilePath := Copy(CommandLine, 1, QuoteIndex);
      // Убедиться, что путь завершается кавычками
      if FilePath[Length(FilePath)] = '"' then
      begin
        // Найти пробел после кавычек
        SpaceIndex := Pos(' ', Copy(CommandLine, QuoteIndex + 1, Length(CommandLine)));
        if SpaceIndex > 0 then
        begin
          // Извлечь подстроку до пробела после кавычек
          FilePath := Copy(FilePath, 1, QuoteIndex) + Copy(CommandLine, QuoteIndex + 1, SpaceIndex);
        end;
        Result := FilePath;
      end;
    end;
  end;
end;
procedure TOptimizer.RegJump(const KeyPath: string);
var
  ExePath: string;
begin
  // Формируем полный путь к исполняемому файлу regjump.exe
  ExePath := ExtractFilePath(ParamStr(0)) + 'regjump.exe';

  // Выполняем ShellExecute для запуска regjump.exe с указанием пути
  ShellExecute(0, 'open', PChar(ExePath), PChar(KeyPath), nil, SW_SHOWNORMAL);
end;

procedure TOptimizer.OpenFolder(const FolderPath: string);
begin
  ShellExecute(0, 'open', PChar('explorer.exe'), Pchar(FolderPath), nil, SW_SHOWNORMAL);
end;
procedure DisableTelemetryTasks;
var
  Command: string;
begin
  // Команда для отключения задачи телеметрии
  Command := 'schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE';
  winopt.SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft','DisableTasksTelemetry',1);
  // Выполнение команды через ShellExecute
  if ShellExecute(0, 'open', 'cmd.exe', PChar('/c ' + Command), nil, SW_HIDE) <= 32 then
    ShowMessage('Не удалось отключить задачу телеметрии.');
end;

function ExecuteCommand(const Command: string; Output: TStrings): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  SecurityAttr: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  BytesRead: DWORD;
  Buffer: array [0..255] of AnsiChar;
  Apprunning: DWORD;
begin
  Result := False;
  with SecurityAttr do
  begin
    nLength := SizeOf(TSecurityAttributes);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(ReadPipe, WritePipe, @SecurityAttr, 0);
  try
    FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
    StartupInfo.cb := SizeOf(TStartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdInput := ReadPipe;
    StartupInfo.hStdOutput := WritePipe;
    StartupInfo.hStdError := WritePipe;
    if CreateProcess(nil, PChar(Command), @SecurityAttr, @SecurityAttr, True, NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then
    begin
      repeat
        Apprunning := WaitForSingleObject(ProcessInfo.hProcess, 100);
        Application.ProcessMessages;
        while PeekNamedPipe(ReadPipe, @Buffer, SizeOf(Buffer), @BytesRead, nil, nil) do
        begin
          BytesRead := 0;
          ReadFile(ReadPipe, Buffer, SizeOf(Buffer) - 1, BytesRead, nil);
          Buffer[BytesRead] := #0;
          OemToAnsi(Buffer, Buffer);
          Output.Add(StrPas(Buffer));
        end;
      until (Apprunning <> WAIT_TIMEOUT);
      Result := True;
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
    end;
  finally
    CloseHandle(ReadPipe);
    CloseHandle(WritePipe);
  end;
end;
procedure TOptimizer.DeleteRegistryKey(const KeyPath: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try

    if Reg.DeleteKey(KeyPath) then
      ShowMessage('Key deleted successfully.')
    else
      ShowMessage('Failed to delete registry key.');
  finally
    Reg.Free;
  end;
end;

procedure TOptimizer.UninstallUWPApp(const PackageName: string);


begin
  DeleteRegistryKey('Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages\' + PackageName);
end;
procedure TOptimizer.GetUWPApps(List: TStrings);
var
  Reg: TRegistry;
  SubKeys: TStringList;
  i: Integer;
begin
  List.Clear;
  Reg := TRegistry.Create;
  SubKeys := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly('Software\Classes\ActivatableClasses\Package') then
    begin
      Reg.GetKeyNames(SubKeys);
      for i := 0 to SubKeys.Count - 1 do
        List.Add(SubKeys[i]);
    end;
  finally
    Reg.Free;
    SubKeys.Free;
  end;
end;

procedure TOptimizer.ReadAllAutoStartKeys(List: TStrings);
var
  Reg: TRegistry;
  KeyNames: TStrings;
  i: Integer;
begin
  List.Clear;

  Reg := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY); // Повышаем права доступа для 64-битных ключей
  try
    // HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
    if Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') then
    begin
      KeyNames := TStringList.Create;
      try
        Reg.GetValueNames(KeyNames);
        for i := 0 to KeyNames.Count - 1 do
          List.Add('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run\' + KeyNames[i] + '=' + Reg.ReadString(KeyNames[i]));
      finally
        KeyNames.Free;
      end;
    end;

    // HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run
    Reg.RootKey := HKEY_LOCAL_MACHINE; // Смена корневого ключа на HKEY_LOCAL_MACHINE
    if Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run') then
    begin
      KeyNames := TStringList.Create;
      try
        Reg.GetValueNames(KeyNames);
        for i := 0 to KeyNames.Count - 1 do
          List.Add('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run\' + KeyNames[i] + '=' + Reg.ReadString(KeyNames[i]));
      finally
        KeyNames.Free;
      end;
    end;
     Reg.RootKey := HKEY_LOCAL_MACHINE;
    // HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run
    if Reg.OpenKeyReadOnly('\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') then
    begin
      KeyNames := TStringList.Create;
      try
        Reg.GetValueNames(KeyNames);
        for i := 0 to KeyNames.Count - 1 do
          List.Add('HKEY_LOCAL_MACHINE\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run\' + KeyNames[i] + '=' + Reg.ReadString(KeyNames[i]));
      finally
        KeyNames.Free;
      end;
    end;

    // Возвращаем корневой ключ обратно к HKEY_CURRENT_USER
    Reg.RootKey := HKEY_CURRENT_USER;

    // HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services
    if Reg.OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Services') then
    begin
      KeyNames := TStringList.Create;
      try
        Reg.GetKeyNames(KeyNames);
        for i := 0 to KeyNames.Count - 1 do
          if Reg.KeyExists(KeyNames[i] + '\Parameters') then
            List.Add('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\' + KeyNames[i] + '\Parameters\' + '=' + Reg.ReadString(KeyNames[i] + '\Parameters'));
      finally
        KeyNames.Free;
      end;
    end;
  finally
    Reg.Free;
  end;
end;

function OpenPolicy; external advapi32 name 'OpenPolicy';
procedure TOptimizer.setOption(option: integer);
var
    Temp: TStringList;
    i: Integer;
begin
  case option of
    0: begin

    end;
    1: begin
           Case form1.ToggleSwitch1.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','ClearPageFileAtShutdown',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','LargeSystemCache',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurretControlSet\Control\Session Manager\Memory Management','DisablePagingExecutive',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\msahci\Parameters','AHCI Link Power Management',0);
                         WriteBinaryValue('Control Panel\Desktop','UserPreferencesMask', [$9E, $3E, $07, $80, $12, $00, $00, $00], false);
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects','VisualFXSetting',2);
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','ListviewShadow',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','DisableNX ',1);
                   case Form1.CheckBox1.Checked of
                   True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','ListviewShadow',0);
                   end;
                   False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','ListviewShadow',1);
                   end;
                 end;
                   case Form1.CheckBox2.Checked of
                   True: begin
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Desktop','MenuShowDelay',0);
                   end;
                   False: begin
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Desktop','MenuShowDelay',200);
                   end;

                 end;
                 Form1.CheckBox1.Enabled:=false;
                 Form1.CheckBox2.Enabled:=false;

            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','ClearPageFileAtShutdown',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','LargeSystemCache',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','DisablePagingExecutive',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\msahci\Parameters','AHCI Link Power Management',1);
                         WriteBinaryValue('Control Panel\Desktop','UserPreferencesMask', [$90, $24, $03, $80, $10, $00, $00, $00], false);
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects','VisualFXSetting',0);
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','ListviewShadow',1);
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Desktop','MenuShowDelay',200);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','DisableNX ',0);
                 Form1.CheckBox1.Enabled:=true;
                 Form1.CheckBox2.Enabled:=true;
            end;

           End;
           form1.Button9.Visible:=true;
    end;
    2: begin
           Case form1.ToggleSwitch2.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpWindowSize',65535);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters','NetbiosOptions',2);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient','EnableMulticast',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpWindowSize',8192);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters','NetbiosOptions',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient','EnableMulticast',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    3: begin
           Case form1.ToggleSwitch3.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting','Disabled',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting','Disabled',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    4: begin
           Case form1.ToggleSwitch4.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags','DisableCompatibilityAssistant',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags','DisableCompatibilityAssistant',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    5: begin
           Case form1.ToggleSwitch5.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    6: begin
           Case form1.ToggleSwitch6.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Fax','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Fax','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    7: begin
           Case form1.ToggleSwitch7.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\StickyNotes','DisableOnDesktop',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\StickyNotes','DisableOnDesktop',0);
            end;
           End;

     end;
    8: begin
           Case form1.ToggleSwitch8.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer','SmartScreenEnabled',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer','SmartScreenEnabled',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    9: begin
           Case form1.ToggleSwitch10.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore','DisableConfig',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore','DisableSR',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore','DisableConfig',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore','DisableSR',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    10: begin
           Case form1.ToggleSwitch11.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters','EnableSuperfetch',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters','EnableSuperfetch',1);
            end;
           End;
           Case form1.ToggleSwitch11.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power','EnableSuperfetch',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power','EnableSuperfetch',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    12: begin
           Case form1.ToggleSwitch13.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    13: begin
           Case form1.ToggleSwitch14.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    14: begin
           Case form1.ToggleSwitch15.IsOn of
            True: begin

                 Temp:=TStringList.Create;
                   Temp.text:=GetInstalledOfficeVersions;
                   for i := 0 to temp.Count-1 do
                      begin
                          SetRegDWORDAdmin(ConCat('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Office\',temp[i],'\Telemetry'),'DisableTelemetry',1);
                      end;
                   temp.Free;
            end;
            False: begin
                 Temp:=TStringList.Create;
                   Temp.text:=GetInstalledOfficeVersions;
                   for i := 0 to temp.Count-1 do
                      begin
                          SetRegDWORDAdmin(ConCat('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Office\',temp[i],'\Telemetry'),'DisableTelemetry',0);
                      end;
                   temp.Free;
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    15: begin
           Case form1.ToggleSwitch16.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Mozilla\Firefox','DisableTelemetry',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Mozilla\Firefox','DisableTelemetry',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    16: begin
           Case form1.ToggleSwitch17.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome','MetricsReportingEnabled',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome','MetricsReportingEnabled',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    17: begin
           Case form1.ToggleSwitch18.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\TDLClient','TDLClient',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\TDLClient','TDLClient',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    18: begin
           Case form1.ToggleSwitch19.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\VisualStudio\SQM','DisableCustomerImprovementProgram',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\VisualStudio\SQM','DisableCustomerImprovementProgram',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    19: begin
           Case form1.ToggleSwitch9.IsOn of
            True: begin
                         DisableTelemetryTasks
            end;
            False: begin
//                         DisableTelemetryTasks
            winopt.SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft','DisableTasksTelemetry',0);
            end;
           End;
     end;
    20: begin
           Case form1.ToggleSwitch20.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\MediaPlayer\Preferences','HME',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\MediaPlayer\Preferences','HME',1);
            end;
           End;
     end;
    21: begin
           Case form1.ToggleSwitch21.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\HomeGroup','DisableHomeGroup',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\HomeGroup','DisableHomeGroup',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    22: begin
           Case form1.ToggleSwitch22.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB1',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB1',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    23: begin
           Case form1.ToggleSwitch23.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB2',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB2',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    24: begin
           Case form1.ToggleSwitch24.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',0);
                                  form1.CheckBox3.Enabled:=false;
                                  form1.CheckBox4.Enabled:=false;
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',1);
                                  form1.CheckBox3.Enabled:=true;
                                  form1.CheckBox4.Enabled:=true;
            end;
           End;

     end;
    25: begin
           Case form1.ToggleSwitch25.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',1);
            end;
           End;
     end;
    26: begin
           Case form1.ToggleSwitch26.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','LongPathsEnabled',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','LongPathsEnabled',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    27: begin
           Case form1.ToggleSwitch27.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\TPM','OSManagedAuthLevel',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\TPM','OSManagedAuthLevel',5);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    28: begin
           Case form1.ToggleSwitch28.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SensrSvc','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SensrSvc','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    29: begin
           Case form1.ToggleSwitch29.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Connect','AllowCastToDlnaDevice',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Connect','AllowCastToDlnaDevice',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    30: begin
           Case form1.ToggleSwitch30.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\MTCUVC','EnableMtcUvc',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\MTCUVC','EnableMtcUvc',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    31: begin
           Case form1.ToggleSwitch31.IsOn of
            True: begin
                       SetClassicPhotoViewerMode(Restore);
                       SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\oldviewerpic','activate',1);
            end;
            False: begin
                       SetClassicPhotoViewerMode(Disable);
                       SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\oldviewerpic','activate',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    32: begin
           Case form1.ToggleSwitch32.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DiagTrack','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DiagTrack','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    33: begin
           Case form1.ToggleSwitch33.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search','AllowCortana',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search','AllowCortana',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    34: begin
           Case form1.ToggleSwitch34.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection','DisableDeviceDataCollectionNotification',1);
                         if form1.CheckBox5.Checked then
                           begin
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','OptIn',0);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy',1);
                           end

                         else
                           begin
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','OptIn',1);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy ',0);
                           end;
                           form1.CheckBox5.Enabled:=false;
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','OptIn',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection','DisableDeviceDataCollectionNotification',0);
                         form1.CheckBox5.Enabled:=true;
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    35: begin
           Case form1.ToggleSwitch35.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer','DisableAds',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer','DisableAds',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    36: begin
           Case form1.ToggleSwitch36.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','DisableTelemetry',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','DisableTelemetry',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    37: begin
           Case form1.ToggleSwitch37.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU','NoAutoUpdate',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU','NoAutoUpdate',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    38: begin
           Case form1.ToggleSwitch38.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','AutoDownload',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','AutoDownload',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    39: begin
           Case form1.ToggleSwitch39.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsInsiderProgram','DisableInsiderHub',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsInsiderProgram','DisableInsiderHub',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    40: begin
           Case form1.ToggleSwitch40.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','ExcludeWUDriversInQualityUpdate',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','ExcludeWUDriversInQualityUpdate',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    41: begin
           Case form1.ToggleSwitch40.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    42: begin
           Case form1.ToggleSwitch42.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\GameBar','AllowAutoGameMode',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\GameBar','AllowAutoGameMode',0);
            end;
           End;
     end;
    43: begin
           Case form1.ToggleSwitch43.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','DisableXboxLive',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','DisableXboxLive',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    44: begin
           Case form1.ToggleSwitch44.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR','AppCaptureEnabled',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR','AppCaptureEnabled',1);
            end;
           End;
     end;
    45: begin
           Case form1.ToggleSwitch45.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Mouse','MousePollingRate',1000);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Mouse','MousePollingRate',100);
            end;
           End;
     end;
    46: begin
           Case form1.ToggleSwitch46.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\0cc5b647-c1df-4637-891a-dec35c318583','Attributes',2);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7','Attributes',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\0cc5b647-c1df-4637-891a-dec35c318583','Attributes',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7','Attributes',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    47: begin
           Case form1.ToggleSwitch47.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','EnableLUA',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','EnableLUA',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    48: begin
           Case form1.ToggleSwitch48.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Shared Tools\Proofing Tools\1.0\Override','Spelling',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Shared Tools\Proofing Tools\1.0\Override','Spelling',1);
            end;
           End;
     end;
    49: begin
           Case form1.ToggleSwitch49.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','AllowClipboardHistory',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','AllowClipboardHistory',1);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    50: begin
           Case form1.ToggleSwitch50.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','HideNewsFeed',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','HideNewsFeed',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    51: begin
           Case form1.ToggleSwitch52.IsOn of
            True: begin
                                                  SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PnP','PollBootPartitionTimeoutVerifyDrivers',75300);
            end;
            False: begin
                                                  SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PnP','PollBootPartitionTimeoutVerifyDrivers',7530);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    52: begin
           Case form1.ToggleSwitch54.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','CrashDumpEnabled',0);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','CrashDumpEnabled',7);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    53: begin
           Case form1.ToggleSwitch53.IsOn of
            True: begin
                          //bcdedit /set nointegritychecks on
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager','VerifyDrivers',0);
                         RunExecPid(Concat(GetEnvironmentVariable('WINDIR'),'\system32\bcdedit.exe /set nointegritychecks on'),false,true,false);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager','VerifyDrivers',1);
                         RunExecPid(Concat(GetEnvironmentVariable('WINDIR'),'\system32\bcdedit.exe /set nointegritychecks off'),false,true,false);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    54: begin
           Case form1.ToggleSwitch57.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender','DisableAntiSpyware',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender','DisableAntiSpyware',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    55: begin
           Case form1.ToggleSwitch58.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoReboot',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoRecovery',0);
                          RunExecPid(Concat(GetEnvironmentVariable('WINDIR'),'\system32\bcdedit.exe /set recoveryenabled  No'),false,true,false);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoReboot',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoRecovery',1);
                          RunExecPid(Concat(GetEnvironmentVariable('WINDIR'),'\system32\bcdedit.exe /set recoveryenabled  Yes'),false,true,false);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    56: begin
           Case form1.ToggleSwitch59.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vgk','Start',4);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vgk','Start',4);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vgk','Start',2);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vgk','Start',2);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    57: begin
           Case form1.ToggleSwitch56.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WerSvc','Start',4);

            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WerSvc','Start',2);

            end;
           End;
           form1.Button9.Visible:=true;
     end;
    58: begin
           Case form1.ToggleSwitch55.IsOn of
            True: begin
                        SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoReboot',0);

            end;
            False: begin
                        SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoReboot',1);

            end;
           End;
           form1.Button9.Visible:=true;
     end;
  {Games Boost Speed}
    59: begin
           Case form1.ToggleSwitch51.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','Win32PrioritySeparation',2);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','Win32PrioritySeparation',18);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    60: begin
           Case form1.ToggleSwitch60.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','ConvertibleSlateMode',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','ConvertibleSlateMode',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
   61: begin
           Case form1.ToggleSwitch61.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','NetworkThrottlingIndex',65535);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','SystemResponsiveness',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','IRQPriority',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Affinity',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','NetworkThrottlingIndex',10);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','SystemResponsiveness',1);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','IRQPriority',0);
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Affinity',0);
                   end;
           End;
           form1.Button9.Visible:=true;
     end;
   62: begin
           Case form1.ToggleSwitch62.IsOn of
            True: begin
                         SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Scheduling Category','High');
                         SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','SFIO Priority','High');
                         SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Background Only','High');
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Priority',1);
            end;
            False: begin
                         SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Scheduling Category','Medium');
                         SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','SFIO Priority','Normal');
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Priority',0);
                                                  SetRegStringAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Background Only','Normal');
                   end;
           End;
           form1.Button9.Visible:=true;
     end;
    63: begin
           Case form1.ToggleSwitch63.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 0);
                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 1);
                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 1);

                          SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 0);
                          SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 1);
                          SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 1);

                          SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 0);
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 1);
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 1);

                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 0);
                          SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 0);
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 0);

                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 0);
                          SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 0);
                          SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 0);

                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'DisableVidMemVBs', 0);
                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'MMX Fast Path', 1);
                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'FlipNoVsync', 1);

                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 0);

                          SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\DirectDraw', 'EmulationOnly', 0);

            end;
            False: begin
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 1);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 0);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 0);

                            SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 1);
                            SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 0);
                            SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 0);

                            SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'DisableVidMemVBs', 1);
                            SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'MMX Fast Path', 0);
                            SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D', 'FlipNoVsync', 0);

                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 1);
                            SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 1);
                            SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 1);

                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 1);
                            SetRegDWORDAdmin('HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 1);
                            SetRegDWORDAdmin('HKEY_CURRENT_USER\SOFTWARE\Microsoft\DirectDraw', 'EmulationOnly', 1);

                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'DisableVidMemVBs', 1);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'MMX Fast Path', 0);
                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D', 'FlipNoVsync', 0);

                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Direct3D\Drivers', 'SoftwareOnly', 1);

                            SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\DirectDraw', 'EmulationOnly', 1);

            end;
           End;
           form1.Button9.Visible:=true;
     end;
    67: begin
           Case form1.ToggleSwitch67.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','DisableDeleteNotification',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','DisableDeleteNotification',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    68: begin
           Case form1.ToggleSwitch68.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','LargeSystemCache',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','LargeSystemCache',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    69: begin
           Case form1.ToggleSwitch69.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisable8dot3NameCreation',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisable8dot3NameCreation',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    70: begin
           Case form1.ToggleSwitch70.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    73: begin
           Case form1.ToggleSwitch73.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Video','PreferredPowerScheme',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Video','PreferredPowerScheme',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    74: begin
           Case form1.ToggleSwitch74.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvCplApi\Policies','QualityFlags',00001200);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvCplApi\Policies','QualityFlags',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    75: begin
           Case form1.ToggleSwitch75.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\DX12MaxFrameLatency','MaxFrameLatencyMode ',3);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\DX12MaxFrameLatency','MaxFrameLatencyMode ',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    76: begin
           Case form1.ToggleSwitch76.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvTweak','THT',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvTweak','THT',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    77: begin
           Case form1.ToggleSwitch77.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\SFR','0x00000003',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\SFR','0x00000003',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;

    78: begin
           Case form1.ToggleSwitch68.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpAckFrequency',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpAckFrequency',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;


    79: begin
           Case form1.ToggleSwitch69.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpNoDelay',1);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpNoDelay',0);
            end;
           End;
           form1.Button9.Visible:=true;
     end;


    80: begin
           Case form1.ToggleSwitch80.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpWindowSize',64240);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpWindowSize',65535);
            end;
           End;
           form1.Button9.Visible:=true;
     end;
    81: begin
           Case form1.ToggleSwitch81.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','MaxUserPort',65534);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','MaxUserPort',5000);
            end;
           End;
           form1.Button9.Visible:=true;
     end;

    82: begin
           Case form1.ToggleSwitch82.IsOn of
            True: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpMaxDataRetransmissions',10);
            end;
            False: begin
                         SetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpMaxDataRetransmissions',5);
            end;
           End;
           form1.Button9.Visible:=true;
     end;

  end;



end;

procedure SetClassicPhotoViewerMode(Mode: TPhotoViewerMode);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    if Mode = Restore then
    begin
      // Восстановление Классического просмотрщика фотографий
      Reg.OpenKey('Applications\photoviewer.dll', True);
      Reg.WriteString('FriendlyAppName', 'Windows Photo Viewer');
      Reg.WriteString('Capabilities\FileAssociations', '.bmp;.dib;.gif;.jfif;.jpe;.jpeg;.jpg;.png;.tif;.tiff');
      Reg.CreateKey('shell\open\command');
      Reg.WriteString('shell\open\command\Default', '"%SystemRoot%\System32\rundll32.exe" "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1');
      Reg.CreateKey('shell\print');
      Reg.WriteString('shell\print\MuiVerb', 'Print');
    end
    else
    begin
      // Отключение Классического просмотрщика фотографий
      Reg.DeleteKey('Applications\photoviewer.dll');
    end;
  finally
    Reg.Free;
  end;
end;

function GetInstalledOfficeVersions: String;
var
  Reg: TRegistry;
  SubKeys: TStringList;
  i: Integer;
  OfficeVersion: string;
begin
  SubKeys := TStringList.Create;
  try
    Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      // Открываем раздел реестра, содержащий версии Microsoft Office
      if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Office') then
      begin
        // Получаем список всех подключей (версий Office)
        Reg.GetKeyNames(SubKeys);
          // Добавляем версию Office в результат

          Result:= SubKeys.Text;
      end;
    finally
      Reg.Free;
    end;
  finally
    SubKeys.Free;
  end;
end;

procedure TOptimizer.SetRegString(const Key: string; const ValueName: string; const Data: string);
var
  RegistryIniFile: TRegistryIniFile;
begin
  RegistryIniFile := TRegistryIniFile.Create('');
  try
    RegistryIniFile.WriteString(Key, ValueName, Data);
  finally
    RegistryIniFile.Free;
  end;
end;

function TOptimizer.GetRegString(const Key: string; const ValueName: string; const DefaultValue: string): string;
var
  RegistryIniFile: TRegistryIniFile;
begin
  RegistryIniFile := TRegistryIniFile.Create('');
  try
    Result := RegistryIniFile.ReadString(Key, ValueName, DefaultValue);
  finally
    RegistryIniFile.Free;
  end;
end;

function IsAdmin: Boolean;
var
  osVersionInfo: TOSVersionInfo;
begin
  Result := False;
  osVersionInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVersionInfo) then
    if (osVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT) and (osVersionInfo.dwMajorVersion >= 5) then
      Result := ShellExecute(0, 'runas', 'cmd.exe', '/c echo Administrative privileges granted.', nil, SW_HIDE) > 32;
end;
procedure TOptimizer.WriteBinaryValue(const Key: string; const ValueName: string; Data: array of Byte; UseHKLM: Boolean);
var
  Registry: TRegistry;
  RootKey: HKEY;
begin
  Registry := TRegistry.Create;
  try
    if UseHKLM then
      RootKey := HKEY_LOCAL_MACHINE
    else
      RootKey := HKEY_CURRENT_USER;

    if not IsAdmin then
      begin
         ShowMessage('Для записи в HKLM необходимы административные права.');
         exit;
      end;

    Registry.RootKey := RootKey;
    if Registry.OpenKey(Key, True) then
    begin
      Registry.WriteBinaryData(ValueName, Data, Length(Data));
      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TOptimizer.SetRegDWORDAdmin(const Key: string; const ValueName: string; const Data: Integer);
var
  Registry: TRegistry;
  RootKey: HKEY;
  SubKey: string;
begin
  if IsAdmin then
  begin
    // Разделяем строку Key на RootKey и SubKey
    if Pos('HKEY_LOCAL_MACHINE\', Key) = 1 then
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      SubKey := Copy(Key, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt);
    end
    else if Pos('HKEY_CURRENT_USER\', Key) = 1 then
    begin
      RootKey := HKEY_CURRENT_USER;
      SubKey := Copy(Key, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
    end
    else if Pos('HKEY_USERS\', Key) = 1 then
    begin
      RootKey := HKEY_USERS;
      SubKey := Copy(Key, Length('HKEY_USERS\') + 1, MaxInt);
    end
    else
    begin
      ShowMessage(ConCat('Некорректный путь в реестре.',key));
      Exit;
    end;

    Registry := TRegistry.Create(KEY_WRITE);
    try
      Registry.RootKey := RootKey;
      if Registry.OpenKey(SubKey, True) then
      begin
        Registry.WriteInteger(ValueName, Data);
        Registry.CloseKey;
      end;
    finally
      Registry.Free;
    end;
  end
  else
    ShowMessage('Для записи в реестр необходимы административные права.');
end;

procedure TOptimizer.LoadOptions;
var
  temp: TStringList;
  i: Integer;
begin
        case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','ListviewShadow',0) of
            0:  Form1.CheckBox1.Checked:=true;
            1:  Form1.CheckBox1.Checked:=False;
        end;
        case GetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Desktop','MenuShowDelay',0) of
           0:  Form1.CheckBox2.Checked:=true;
           else  Form1.CheckBox2.Checked:=False;
        end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','ClearPageFileAtShutdown',0) of
    0: begin
        Form1.ToggleSwitch1.state:=tssOff;
    end;
    1: begin
        Form1.ToggleSwitch1.state:=tssOn;

    end;
   end;

   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient','EnableMulticast',0) of
    0:  Form1.ToggleSwitch2.state:=tssON;
    1:  Form1.ToggleSwitch2.state:=tssOFF;
   end;

   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting','Disabled',0) of
    1:  Form1.ToggleSwitch3.state:=tssON;
    0:  Form1.ToggleSwitch3.state:=tssOFF;
   end;

   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags','DisableCompatibilityAssistant',0) of
    1:  Form1.ToggleSwitch4.state:=tssON;
    0:  Form1.ToggleSwitch4.state:=tssOFF;
   end;

   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Spooler','Start',2) of
    4:  Form1.ToggleSwitch5.state:=tssON;
    2:  Form1.ToggleSwitch5.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Fax','Start',2) of
    4:  Form1.ToggleSwitch6.state:=tssON;
    2:  Form1.ToggleSwitch6.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\StickyNotes','DisableOnDesktop',0) of
    1:  Form1.ToggleSwitch7.state:=tssON;
    0:  Form1.ToggleSwitch7.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer','SmartScreenEnabled',0) of
    0:  Form1.ToggleSwitch8.state:=tssON;
    1:  Form1.ToggleSwitch8.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore','DisableConfig',0) of
    1:  Form1.ToggleSwitch10.state:=tssON;
    0:  Form1.ToggleSwitch10.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power','EnableSuperfetch',0) of
    0:  Form1.ToggleSwitch11.state:=tssON;
    1:  Form1.ToggleSwitch11.state:=tssOFF;
   end;
//   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power','EnableSuperfetch',0) of
//    0:  Form1.ToggleSwitch12.state:=tssON;
//    1:  Form1.ToggleSwitch12.state:=tssOFF;
//   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',0) of
    1:  Form1.ToggleSwitch13.state:=tssON;
    0:  Form1.ToggleSwitch13.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',2) of
    4:  Form1.ToggleSwitch14.state:=tssON;
    2:  Form1.ToggleSwitch14.state:=tssOFF;
   end;
    Temp:=TStringList.Create;
    Temp.text:=GetInstalledOfficeVersions;
    Form1.ToggleSwitch15.state:=tssOFF;
    for i := 0 to temp.Count-1 do
        begin
          if GetRegDWORDAdmin(ConCat('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Office\',temp[i],'\Telemetry'),'DisableTelemetry',0) = 1 then Form1.ToggleSwitch15.state:=tssON;
        end;
   temp.Free;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Mozilla\Firefox','DisableTelemetry',0) of
    1:  Form1.ToggleSwitch16.state:=tssON;
    0:  Form1.ToggleSwitch16.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome','MetricsReportingEnabled',0) of
    0:  Form1.ToggleSwitch17.state:=tssOFF;
    1:  Form1.ToggleSwitch17.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\TDLClient','TDLClient',0) of
    0:  Form1.ToggleSwitch18.state:=tssON;
    1:  Form1.ToggleSwitch18.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\VisualStudio\SQM','DisableCustomerImprovementProgram',0) of
    1:  Form1.ToggleSwitch19.state:=tssON;
    0:  Form1.ToggleSwitch19.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft','DisableTasksTelemetry',0) of
    1:  Form1.ToggleSwitch9.state:=tssON;
    0:  Form1.ToggleSwitch9.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\MediaPlayer\Preferences','HME',0) of
    0:  Form1.ToggleSwitch20.state:=tssON;
    1:  Form1.ToggleSwitch20.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\HomeGroup','DisableHomeGroup',0) of
    1:  Form1.ToggleSwitch21.state:=tssON;
    0:  Form1.ToggleSwitch21.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB1',1) of
    0:  Form1.ToggleSwitch22.state:=tssON;
    1:  Form1.ToggleSwitch22.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters','SMB2',1) of
    0:  Form1.ToggleSwitch23.state:=tssON;
    1:  Form1.ToggleSwitch23.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',1) of
    0:  begin
         Form1.ToggleSwitch24.state:=tssON;
         form1.CheckBox3.Enabled:=false;
         form1.CheckBox4.Enabled:=false;
    end;
    1:  begin
         Form1.ToggleSwitch24.state:=tssOFF;
         form1.CheckBox3.Enabled:=true;
         form1.CheckBox4.Enabled:=true;
    end;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced','PeopleBand',1) of
    0:  Form1.ToggleSwitch25.state:=tssON;
    1:  Form1.ToggleSwitch25.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','LongPathsEnabled',0) of
    1:  Form1.ToggleSwitch26.state:=tssON;
    0:  Form1.ToggleSwitch26.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\TPM','OSManagedAuthLevel',5) of
    4:  Form1.ToggleSwitch27.state:=tssON;
    5:  Form1.ToggleSwitch27.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SensrSvc','Start',2) of
    4:  Form1.ToggleSwitch28.state:=tssON;
    2:  Form1.ToggleSwitch28.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Connect','AllowCastToDlnaDevice',1) of
    0:  Form1.ToggleSwitch29.state:=tssON;
    1:  Form1.ToggleSwitch29.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\MTCUVC','EnableMtcUvc',0) of
    1:  Form1.ToggleSwitch30.state:=tssON;
    0:  Form1.ToggleSwitch30.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\oldviewerpic','activate',0) of
    1:  Form1.ToggleSwitch31.state:=tssON;
    0:  Form1.ToggleSwitch31.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DiagTrack','Start',2) of
    4:  Form1.ToggleSwitch32.state:=tssON;
    2:  Form1.ToggleSwitch32.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search','AllowCortana',1) of
    0:  Form1.ToggleSwitch33.state:=tssON;
    1:  Form1.ToggleSwitch33.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','DisabledByGroupPolicy',0) of
    1:  begin
        if GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo','OptIn',1) = 0  then
             form1.CheckBox5.Checked:=true else form1.CheckBox5.Checked:=false;
          form1.CheckBox5.Enabled:=false;
          Form1.ToggleSwitch34.state:=tssON;
    end;
    0:  begin
          Form1.ToggleSwitch34.state:=tssOFF;
          form1.CheckBox5.Checked:=false;
          form1.CheckBox5.Enabled:=true;
    end;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer','DisableAds',0) of
    1:  Form1.ToggleSwitch35.state:=tssON;
    0:  Form1.ToggleSwitch35.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','DisableTelemetry',0) of
    1:  Form1.ToggleSwitch36.state:=tssON;
    0:  Form1.ToggleSwitch36.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU','NoAutoUpdate',0) of
    1:  Form1.ToggleSwitch37.state:=tssON;
    0:  Form1.ToggleSwitch37.state:=tssOFF;
   end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','AutoDownload',2) of
    4:  Form1.ToggleSwitch38.state:=tssON;
    2:  Form1.ToggleSwitch38.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsInsiderProgram','DisableInsiderHub',0) of
    1:  Form1.ToggleSwitch39.state:=tssON;
    0:  Form1.ToggleSwitch39.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate','ExcludeWUDriversInQualityUpdate',0) of
    1:  Form1.ToggleSwitch40.state:=tssON;
    0:  Form1.ToggleSwitch40.state:=tssOFF;
   end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch','Start',2) of
    4:  Form1.ToggleSwitch41.state:=tssON;
    2:  Form1.ToggleSwitch41.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\GameBar','AllowAutoGameMode',0) of
    1:  Form1.ToggleSwitch42.state:=tssON;
    0:  Form1.ToggleSwitch42.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore','DisableXboxLive',0) of
    1:  Form1.ToggleSwitch43.state:=tssON;
    0:  Form1.ToggleSwitch43.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR','AppCaptureEnabled',0) of
    0:  Form1.ToggleSwitch44.state:=tssON;
    1:  Form1.ToggleSwitch44.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Control Panel\Mouse','MousePollingRate',100) of
    1000:  Form1.ToggleSwitch45.state:=tssON;
    100:  Form1.ToggleSwitch45.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\0cc5b647-c1df-4637-891a-dec35c318583','Attributes',1) of
    2:  Form1.ToggleSwitch46.state:=tssON;
    1:  Form1.ToggleSwitch46.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','EnableLUA',1) of
    0:  Form1.ToggleSwitch47.state:=tssON;
    1:  Form1.ToggleSwitch47.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_CURRENT_USER\Software\Microsoft\Shared Tools\Proofing Tools\1.0\Override','Spelling',1) of
    0:  Form1.ToggleSwitch48.state:=tssON;
    1:  Form1.ToggleSwitch48.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System','AllowClipboardHistory',1) of
    0:  Form1.ToggleSwitch49.state:=tssON;
    1:  Form1.ToggleSwitch49.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge','HideNewsFeed',0) of
    1:  Form1.ToggleSwitch50.state:=tssON;
    0:  Form1.ToggleSwitch50.state:=tssOFF;
   end;
   LoadStringGrid(form1.JvDotNetCheckListBox1);
   LoadStringUWP(form1.JvDotNetCheckListBox2);
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','CrashDumpEnabled',7) of
    0:  Form1.ToggleSwitch54.state:=tssON;
    else  Form1.ToggleSwitch54.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager','VerifyDrivers',1) of
    0:  Form1.ToggleSwitch53.state:=tssON;
    1:  Form1.ToggleSwitch53.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PnP','PollBootPartitionTimeoutVerifyDrivers',7530) of
    75300:  Form1.ToggleSwitch52.state:=tssON;
    else  Form1.ToggleSwitch52.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender','DisableAntiSpyware',0) of
    1:  Form1.ToggleSwitch57.state:=tssON;
    0:  Form1.ToggleSwitch57.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoReboot',1) of
    0:  Form1.ToggleSwitch55.state:=tssON;
    1:  Form1.ToggleSwitch55.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl','AutoRecovery',1) of
    0:  Form1.ToggleSwitch58.state:=tssON;
    1:  Form1.ToggleSwitch58.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WerSvc','Start',2) of
    4:  Form1.ToggleSwitch56.state:=tssON;
    2:  Form1.ToggleSwitch56.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\vgk','Start',2) of
    4:  Form1.ToggleSwitch59.state:=tssON;
    2:  Form1.ToggleSwitch59.state:=tssOFF;
   end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','Win32PrioritySeparation',18) of
      2:  Form1.ToggleSwitch51.state:=tssON;
      else  Form1.ToggleSwitch51.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl','ConvertibleSlateMode',0) of
      1:  Form1.ToggleSwitch60.state:=tssON;
      0:  Form1.ToggleSwitch60.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Affinity',0) of
      1:  Form1.ToggleSwitch61.state:=tssON;
      0:  Form1.ToggleSwitch61.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games','Priority',0) of
      1:  Form1.ToggleSwitch62.state:=tssON;
      0:  Form1.ToggleSwitch62.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\DirectDraw', 'EmulationOnly', 1) of
      0:  Form1.ToggleSwitch63.state:=tssON;
      1:  Form1.ToggleSwitch63.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Video','PreferredPowerScheme',0) of
      1:  Form1.ToggleSwitch73.state:=tssON;
      0:  Form1.ToggleSwitch73.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvCplApi\Policies','QualityFlags',0) of
      00001200:  Form1.ToggleSwitch74.state:=tssON;
      0:  Form1.ToggleSwitch74.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\DX12MaxFrameLatency','MaxFrameLatencyMode ',0) of
      3:  Form1.ToggleSwitch75.state:=tssON;
      0:  Form1.ToggleSwitch75.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\NvTweak','THT',0) of
      1:  Form1.ToggleSwitch76.state:=tssON;
      0:  Form1.ToggleSwitch76.state:=tssOFF;
     end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SOFTWARE\NVIDIA Corporation\Global\SFR','0x00000003',0) of
      1:  Form1.ToggleSwitch77.state:=tssON;
      else  Form1.ToggleSwitch77.state:=tssOFF;
     end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','DisableDeleteNotification',0) of
    1:  Form1.ToggleSwitch67.state:=tssON;
    0:  Form1.ToggleSwitch67.state:=tssOFF;
   end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management','LargeSystemCache',0) of
    1:  Form1.ToggleSwitch68.state:=tssON;
    0:  Form1.ToggleSwitch68.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisable8dot3NameCreation',0) of
    1:  Form1.ToggleSwitch69.state:=tssON;
    0:  Form1.ToggleSwitch69.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem','NtfsDisableLastAccessUpdate',0) of
    1:  Form1.ToggleSwitch70.state:=tssON;
    0:  Form1.ToggleSwitch70.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpAckFrequency',0) of
    1:  Form1.ToggleSwitch78.state:=tssON;
    0:  Form1.ToggleSwitch78.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpNoDelay',0) of
    1:  Form1.ToggleSwitch79.state:=tssON;
    0:  Form1.ToggleSwitch79.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpWindowSize',65535) of
    64240:  Form1.ToggleSwitch80.state:=tssON;
    else  Form1.ToggleSwitch80.state:=tssOFF;
   end;
   case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','MaxUserPort',5000) of
    65534:  Form1.ToggleSwitch81.state:=tssON;
    else Form1.ToggleSwitch81.state:=tssOFF;
   end;
  case GetRegDWORDAdmin('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters','TcpMaxDataRetransmissions',5) of
    10:  Form1.ToggleSwitch82.state:=tssON;
    else  Form1.ToggleSwitch82.state:=tssOFF;
   end;

end;

procedure TOptimizer.LoadStringGrid(grid: TJvDotNetCheckListBox);
var
    temp: TStringList;
       i: Integer;
begin
    grid.Clear;
    temp:=TStringList.Create;
    ReadAllAutoStartKeys(temp);
        grid.Items.Clear;
        for I := 0 to temp.Count-1 do
                grid.Items.add(temp.ValueFromIndex[i]);

    temp.free;

end;

procedure TOptimizer.LoadStringUWP(grid: TJvDotNetCheckListBox);
var
    temp: TStringList;
       i: Integer;
begin
    grid.Clear;
    temp:=TStringList.Create;
    GetUWPApps(temp);
        grid.Items.Clear;
        for I := 0 to temp.Count-1 do
                grid.Items.add(temp.keynames[i]);

    temp.free;
end;

procedure TOptimizer.RestoreAutoStartKeys(const BackupFilePath: string);
var
  Reg: TRegistry;
  AutoStartKeys: TStringList;
  RegKey: string;
  temp: TstringList;
  I: Integer;
   LastSlashPos: Integer;
begin
  // Создаем объект TRegistry

  Reg := TRegistry.Create;
  AutoStartKeys:= TStringList.Create;
  temp:=TStringList.Create;
   AutoStartKeys.LoadFromFile(BackupFilePath) ;

    for i := 0 to AutoStartKeys.Count-1 do
       begin
         temp.Clear;
         temp.Delimiter:='\';
         temp.DelimitedText :=AutoStartKeys.KeyNames[i];

         SetRegStringAdmin(AutoStartKeys.KeyNames[i].Replace(ConCat('\',temp[temp.Count-1]),''),temp[temp.Count-1],AutoStartKeys.ValueFromIndex[i]);

       end;


//  ShowMessage(AutoStartKeys.Text);
  AutoStartKeys.Free;
  temp.Free;
  Reg.Free;
end;


             function hideWinByPid(wHandle: HWND;  pid1: DWORD): BOOL; stdcall;
              var
              sImageFileName: array [0..MAX_PATH] of Char;
              pid : DWORD;
              pHandle : THandle;
              s: string ;
              begin
                Result := true;
                GetWindowThreadProcessId(wHandle, @pid);
                if pid = pid1 then begin
                  showwindow(wHandle, SW_hide);

                end;
                CloseHandle(pHandle);
              end;

function TOptimizer.RunExecPid(ProgramName: String; Wait, hide,
  minimize: boolean): integer;
 var
              StartInfo : TStartupInfo;
              ProcInfo : TProcessInformation;
              CreateOK : Boolean;
            begin
              FillChar(StartInfo,SizeOf(TStartupInfo),#0);
              FillChar(ProcInfo,SizeOf(TProcessInformation),#0);
              UniqueString(ProgramName);
              if hide then begin
                StartInfo.wShowWindow := SW_HIDE;
                StartInfo.dwFlags := STARTF_USESHOWWINDOW;
              end;

              if minimize = true then
                StartInfo.wShowWindow := SW_Minimize;

              StartInfo.cb := SizeOf(TStartupInfo);
              CreateOK := CreateProcess(nil, PChar(ProgramName), nil, nil,False,
                          NORMAL_PRIORITY_CLASS,
                          nil, nil, StartInfo, ProcInfo);
              if CreateOK then begin
                if minimize = true then
                  enumwindows(@hideWinByPid, ProcInfo.dwProcessId);

                Result := ProcInfo.dwProcessId;
                if Wait then
                  WaitForSingleObject(ProcInfo.hProcess, INFINITE);
              end
              else begin
                Result := 0;
              end;
              CloseHandle(ProcInfo.hProcess);
              CloseHandle(ProcInfo.hThread);
            end;


procedure TOptimizer.DeleteRegistryValue(const KeyPath, ValueName: string);
var
  Reg: TRegistry;
  RootKey: HKEY;
  ParentKeyPath: string;
begin
  Reg := TRegistry.Create;
  try
    // Получаем корневой ключ (HKEY_LOCAL_MACHINE или HKEY_CURRENT_USER)
    if Pos('HKEY_LOCAL_MACHINE', KeyPath) = 1 then
      RootKey := HKEY_LOCAL_MACHINE
    else if Pos('HKEY_CURRENT_USER', KeyPath) = 1 then
      RootKey := HKEY_CURRENT_USER
    else
    begin
      ShowMessage('Invalid root key specified.');
      Exit;
    end;

    // Убираем первую часть пути до первой обратной косой черты
    ParentKeyPath := Copy(KeyPath, Pos('\', KeyPath) + 1, Length(KeyPath));

    // Открываем родительский ключ
    Reg.RootKey := RootKey;
    if Reg.OpenKey(ParentKeyPath, False) then
    begin
      // Если родительский ключ открыт успешно, удаляем значение
      if Reg.ValueExists(ValueName) then
      begin
        Reg.DeleteValue(ValueName);
//        ShowMessage('Value deleted successfully.');
      end
      else
        ShowMessage('Value does not exist.');
      Reg.CloseKey;
    end
    else
      ShowMessage('Failed to open registry key.');
  finally
    Reg.Free;
  end;
end;
procedure TOptimizer.BackupAutoStartKeys(const BackupFilePath: string);
var
  Reg: TRegistry;
  AutoStartKeys: TStringList;
  RegKey: string;
begin
  // Создаем объект TRegistry

  Reg := TRegistry.Create;
  AutoStartKeys:= TStringList.Create;
 ReadAllAutoStartKeys(AutoStartKeys);

  AutoStartKeys.SaveToFile(BackupFilePath) ;
  AutoStartKeys.Free;
  Reg.Free;
end;

function TOptimizer.GetRegDWORDAdmin(const Key: string; const ValueName: string; const DefaultValue: Integer): Integer;
var
  Registry: TRegistry;
  RootKey: HKEY;
  SubKey: string;
begin
  Result := DefaultValue; // Устанавливаем значение по умолчанию

  if IsAdmin then
  begin
    // Разделяем строку Key на RootKey и SubKey
    if Pos('HKEY_LOCAL_MACHINE\', Key) = 1 then
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      SubKey := Copy(Key, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt);
    end
    else if Pos('HKEY_CURRENT_USER\', Key) = 1 then
    begin
      RootKey := HKEY_CURRENT_USER;
      SubKey := Copy(Key, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
    end
    else
    begin
      ShowMessage('Некорректный путь в реестре.');
      Exit;
    end;

    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := RootKey;
      if Registry.OpenKeyReadOnly(SubKey) then
      begin
        if Registry.ValueExists(ValueName) then
          Result := Registry.ReadInteger(ValueName);
        Registry.CloseKey;
      end;
    finally
      Registry.Free;
    end;
  end
  else
    ShowMessage('Для чтения из реестра необходимы административные права.');
end;


procedure TOptimizer.SetRegStringAdmin(const Key: string; const ValueName: string; const Data: string);
var
  Registry: TRegistry;
  RootKey: HKEY;
  SubKey: string;
begin
  if IsAdmin then
  begin
    // Разделяем строку Key на RootKey и SubKey
    if Pos('HKEY_LOCAL_MACHINE\', Key) = 1 then
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      SubKey := Copy(Key, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt);
    end
    else if Pos('HKEY_CURRENT_USER\', Key) = 1 then
    begin
      RootKey := HKEY_CURRENT_USER;
      SubKey := Copy(Key, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
    end
    else
    begin
      ShowMessage('Некорректный путь в реестре.');
      Exit;
    end;

    Registry := TRegistry.Create(KEY_WRITE);
    try
      Registry.RootKey := RootKey;
      if Registry.OpenKey(SubKey, True) then
      begin
        Registry.WriteString(ValueName, Data);
        Registry.CloseKey;
      end;
    finally
      Registry.Free;
    end;
  end
  else
    ShowMessage('Для записи в реестр необходимы административные права.');
end;

function TOptimizer.GetRegStringAdmin(const Key: string; const ValueName: string; const DefaultValue: string): string;
var
  Registry: TRegistry;
  RootKey: HKEY;
  SubKey: string;
begin
  Result := DefaultValue; // Устанавливаем значение по умолчанию

  if IsAdmin then
  begin
    // Разделяем строку Key на RootKey и SubKey
    if Pos('HKEY_LOCAL_MACHINE\', Key) = 1 then
    begin
      RootKey := HKEY_LOCAL_MACHINE;
      SubKey := Copy(Key, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt);
    end
    else if Pos('HKEY_CURRENT_USER\', Key) = 1 then
    begin
      RootKey := HKEY_CURRENT_USER;
      SubKey := Copy(Key, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
    end
    else
    begin
      ShowMessage('Некорректный путь в реестре.');
      Exit;
    end;

    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := RootKey;
      if Registry.OpenKeyReadOnly(SubKey) then
      begin
        if Registry.ValueExists(ValueName) then
          Result := Registry.ReadString(ValueName);
        Registry.CloseKey;
      end;
    finally
      Registry.Free;
    end;
  end
  else
    ShowMessage('Для чтения из реестра необходимы административные права.');
end;




function TOptimizer.IntOptToBool(opt: integer): boolean;
begin
    case opt of
      1: Result:=true;
      0: Result:=False;
    end;
end;

end.
