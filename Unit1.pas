unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, JvExComCtrls,
  JvHeaderControl, Vcl.StdCtrls, JvExStdCtrls, JvButton, JvStartMenuButton,
  JvExControls, JvXMLBrowser, Vcl.Tabs, Vcl.ExtCtrls, JvExExtCtrls,
  JvExtComponent, JvPanel, Vcl.WinXCtrls, JvNavigationPane, Vcl.Grids,
  JvExGrids, JvStringGrid, optimizer, Vcl.CheckLst, JvxCheckListBox,
  JvExCheckLst, JvCheckListBox, JvDotNetControls, JvExForms, JvCustomItemViewer,
  JvImageListViewer, Vcl.Imaging.pngimage, JvImageTransform, System.ImageList,
  Vcl.ImgList, JvImageList, JvImage, Vcl.Mask, Vcl.Imaging.jpeg;

type
  TForm1 = class(TForm)
    JvNavPanelHeader1: TJvNavPanelHeader;
    RelativePanel1: TRelativePanel;
    Panel1: TPanel;
    FileSaveDialog1: TFileSaveDialog;
    FileOpenDialog1: TFileOpenDialog;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    JvImageList1: TJvImageList;
    Image1: TImage;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ToggleSwitch1: TToggleSwitch;
    ToggleSwitch2: TToggleSwitch;
    ToggleSwitch3: TToggleSwitch;
    ToggleSwitch4: TToggleSwitch;
    ToggleSwitch5: TToggleSwitch;
    ToggleSwitch6: TToggleSwitch;
    ToggleSwitch7: TToggleSwitch;
    ToggleSwitch8: TToggleSwitch;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    GroupBox14: TGroupBox;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    ToggleSwitch15: TToggleSwitch;
    ToggleSwitch16: TToggleSwitch;
    ToggleSwitch17: TToggleSwitch;
    ToggleSwitch18: TToggleSwitch;
    ToggleSwitch19: TToggleSwitch;
    GroupBox15: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    ToggleSwitch10: TToggleSwitch;
    ToggleSwitch11: TToggleSwitch;
    ToggleSwitch12: TToggleSwitch;
    ToggleSwitch13: TToggleSwitch;
    ToggleSwitch14: TToggleSwitch;
    GroupBox16: TGroupBox;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    ToggleSwitch9: TToggleSwitch;
    ToggleSwitch20: TToggleSwitch;
    ToggleSwitch21: TToggleSwitch;
    ToggleSwitch22: TToggleSwitch;
    ToggleSwitch23: TToggleSwitch;
    TabSheet2: TTabSheet;
    GroupBox17: TGroupBox;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    Label29: TLabel;
    Label30: TLabel;
    Label31: TLabel;
    ToggleSwitch24: TToggleSwitch;
    ToggleSwitch25: TToggleSwitch;
    ToggleSwitch26: TToggleSwitch;
    ToggleSwitch27: TToggleSwitch;
    ToggleSwitch28: TToggleSwitch;
    ToggleSwitch29: TToggleSwitch;
    ToggleSwitch30: TToggleSwitch;
    ToggleSwitch31: TToggleSwitch;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    GroupBox18: TGroupBox;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label50: TLabel;
    ToggleSwitch32: TToggleSwitch;
    ToggleSwitch33: TToggleSwitch;
    ToggleSwitch34: TToggleSwitch;
    CheckBox5: TCheckBox;
    ToggleSwitch35: TToggleSwitch;
    ToggleSwitch36: TToggleSwitch;
    ToggleSwitch50: TToggleSwitch;
    GroupBox19: TGroupBox;
    Label37: TLabel;
    Label38: TLabel;
    Label39: TLabel;
    Label40: TLabel;
    Label41: TLabel;
    ToggleSwitch37: TToggleSwitch;
    ToggleSwitch38: TToggleSwitch;
    ToggleSwitch39: TToggleSwitch;
    ToggleSwitch40: TToggleSwitch;
    ToggleSwitch41: TToggleSwitch;
    GroupBox20: TGroupBox;
    Label42: TLabel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    ToggleSwitch42: TToggleSwitch;
    ToggleSwitch43: TToggleSwitch;
    ToggleSwitch44: TToggleSwitch;
    ToggleSwitch45: TToggleSwitch;
    ToggleSwitch46: TToggleSwitch;
    GroupBox21: TGroupBox;
    Label47: TLabel;
    Label48: TLabel;
    Label49: TLabel;
    ToggleSwitch47: TToggleSwitch;
    ToggleSwitch48: TToggleSwitch;
    ToggleSwitch49: TToggleSwitch;
    TabSheet3: TTabSheet;
    GroupBox3: TGroupBox;
    JvNavPanelDivider1: TJvNavPanelDivider;
    JvDotNetCheckListBox1: TJvDotNetCheckListBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    TabSheet4: TTabSheet;
    GroupBox4: TGroupBox;
    Button7: TButton;
    Button8: TButton;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    JvDotNetCheckListBox2: TJvDotNetCheckListBox;
    TabSheet5: TTabSheet;
    GroupBox5: TGroupBox;
    JvImage1: TJvImage;
    GroupBox22: TGroupBox;
    Label51: TLabel;
    Label52: TLabel;
    Label53: TLabel;
    Label54: TLabel;
    Label55: TLabel;
    Label56: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    ToggleSwitch52: TToggleSwitch;
    ToggleSwitch53: TToggleSwitch;
    ToggleSwitch54: TToggleSwitch;
    ToggleSwitch55: TToggleSwitch;
    ToggleSwitch56: TToggleSwitch;
    ToggleSwitch57: TToggleSwitch;
    ToggleSwitch58: TToggleSwitch;
    ToggleSwitch59: TToggleSwitch;
    TabSheet8: TTabSheet;
    Image2: TImage;
    LinkLabel1: TLinkLabel;
    LinkLabel2: TLinkLabel;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    TabSheet6: TTabSheet;
    GroupBox2: TGroupBox;
    GroupBox6: TGroupBox;
    LabeledEdit2: TLabeledEdit;
    GroupBox1: TGroupBox;
    Label59: TLabel;
    Label60: TLabel;
    Label61: TLabel;
    Label62: TLabel;
    Label63: TLabel;
    ToggleSwitch51: TToggleSwitch;
    ToggleSwitch60: TToggleSwitch;
    ToggleSwitch61: TToggleSwitch;
    ToggleSwitch62: TToggleSwitch;
    ToggleSwitch63: TToggleSwitch;
    GroupBox7: TGroupBox;
    Label67: TLabel;
    Label68: TLabel;
    Label69: TLabel;
    Label70: TLabel;
    ToggleSwitch67: TToggleSwitch;
    ToggleSwitch68: TToggleSwitch;
    ToggleSwitch69: TToggleSwitch;
    ToggleSwitch70: TToggleSwitch;
    GroupBox10: TGroupBox;
    Label73: TLabel;
    Label74: TLabel;
    Label75: TLabel;
    Label76: TLabel;
    Label77: TLabel;
    ToggleSwitch73: TToggleSwitch;
    ToggleSwitch74: TToggleSwitch;
    ToggleSwitch75: TToggleSwitch;
    ToggleSwitch76: TToggleSwitch;
    ToggleSwitch77: TToggleSwitch;
    GroupBox11: TGroupBox;
    Label78: TLabel;
    Label79: TLabel;
    Label80: TLabel;
    Label81: TLabel;
    Label82: TLabel;
    ToggleSwitch78: TToggleSwitch;
    ToggleSwitch79: TToggleSwitch;
    ToggleSwitch80: TToggleSwitch;
    ToggleSwitch81: TToggleSwitch;
    ToggleSwitch82: TToggleSwitch;
    LinkLabel3: TLinkLabel;
    Image6: TImage;
    Image7: TImage;
    Memo1: TMemo;
    Image8: TImage;
    Button9: TButton;
    procedure ToggleSwitch1Click(Sender: TObject);
    procedure ToggleSwitch2Click(Sender: TObject);
    procedure ToggleSwitch3Click(Sender: TObject);
    procedure ToggleSwitch4Click(Sender: TObject);
    procedure ToggleSwitch5Click(Sender: TObject);
    procedure ToggleSwitch6Click(Sender: TObject);
    procedure ToggleSwitch7Click(Sender: TObject);
    procedure ToggleSwitch8Click(Sender: TObject);
    procedure ToggleSwitch10Click(Sender: TObject);
    procedure ToggleSwitch11Click(Sender: TObject);
    procedure ToggleSwitch12Click(Sender: TObject);
    procedure ToggleSwitch14Click(Sender: TObject);
    procedure ToggleSwitch16Click(Sender: TObject);
    procedure ToggleSwitch17Click(Sender: TObject);
    procedure ToggleSwitch18Click(Sender: TObject);
    procedure ToggleSwitch19Click(Sender: TObject);
    procedure ToggleSwitch9Click(Sender: TObject);
    procedure ToggleSwitch20Click(Sender: TObject);
    procedure ToggleSwitch21Click(Sender: TObject);
    procedure ToggleSwitch22Click(Sender: TObject);
    procedure ToggleSwitch23Click(Sender: TObject);
    procedure ToggleSwitch24Click(Sender: TObject);
    procedure ToggleSwitch25Click(Sender: TObject);
    procedure ToggleSwitch26Click(Sender: TObject);
    procedure ToggleSwitch27Click(Sender: TObject);
    procedure ToggleSwitch28Click(Sender: TObject);
    procedure ToggleSwitch29Click(Sender: TObject);
    procedure ToggleSwitch30Click(Sender: TObject);
    procedure ToggleSwitch31Click(Sender: TObject);
    procedure ToggleSwitch32Click(Sender: TObject);
    procedure ToggleSwitch33Click(Sender: TObject);
    procedure ToggleSwitch34Click(Sender: TObject);
    procedure ToggleSwitch35Click(Sender: TObject);
    procedure ToggleSwitch36Click(Sender: TObject);
    procedure ToggleSwitch50Click(Sender: TObject);
    procedure ToggleSwitch37Click(Sender: TObject);
    procedure ToggleSwitch38Click(Sender: TObject);
    procedure ToggleSwitch39Click(Sender: TObject);
    procedure ToggleSwitch40Click(Sender: TObject);
    procedure ToggleSwitch41Click(Sender: TObject);
    procedure ToggleSwitch42Click(Sender: TObject);
    procedure ToggleSwitch43Click(Sender: TObject);
    procedure ToggleSwitch44Click(Sender: TObject);
    procedure ToggleSwitch45Click(Sender: TObject);
    procedure ToggleSwitch46Click(Sender: TObject);
    procedure ToggleSwitch47Click(Sender: TObject);
    procedure ToggleSwitch48Click(Sender: TObject);
    procedure ToggleSwitch49Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToggleSwitch13Click(Sender: TObject);
    procedure ToggleSwitch15Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure JvDotNetCheckListBox1DblClick(Sender: TObject);
    procedure JvDotNetCheckListBox1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure ToggleSwitch52Click(Sender: TObject);
    procedure Label52Click(Sender: TObject);
    procedure ToggleSwitch53Click(Sender: TObject);
    procedure ToggleSwitch54Click(Sender: TObject);
    procedure ToggleSwitch57Click(Sender: TObject);
    procedure ToggleSwitch55Click(Sender: TObject);
    procedure ToggleSwitch56Click(Sender: TObject);
    procedure ToggleSwitch59Click(Sender: TObject);
    procedure ToggleSwitch58Click(Sender: TObject);
    procedure ToggleSwitch82Click(Sender: TObject);
    procedure ToggleSwitch81Click(Sender: TObject);
    procedure ToggleSwitch80Click(Sender: TObject);
    procedure ToggleSwitch79Click(Sender: TObject);
    procedure ToggleSwitch78Click(Sender: TObject);
    procedure ToggleSwitch77Click(Sender: TObject);
    procedure ToggleSwitch76Click(Sender: TObject);
    procedure ToggleSwitch75Click(Sender: TObject);
    procedure ToggleSwitch74Click(Sender: TObject);
    procedure ToggleSwitch73Click(Sender: TObject);
    procedure ToggleSwitch70Click(Sender: TObject);
    procedure ToggleSwitch69Click(Sender: TObject);
    procedure ToggleSwitch68Click(Sender: TObject);
    procedure ToggleSwitch67Click(Sender: TObject);
    procedure ToggleSwitch63Click(Sender: TObject);
    procedure ToggleSwitch62Click(Sender: TObject);
    procedure ToggleSwitch61Click(Sender: TObject);
    procedure ToggleSwitch60Click(Sender: TObject);
    procedure ToggleSwitch51Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
            uses
                ioutils;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  
  if JvDotNetCheckListBox1.ItemIndex >=0 then
    if pos('"',JvDotNetCheckListBox1.Items[JvDotNetCheckListBox1.ItemIndex])>0 then
       begin
            winopt.OpenFolder (ConCat(ExtractFilePath(winopt.ExtractExecutablePath(JvDotNetCheckListBox1.Items[JvDotNetCheckListBox1.ItemIndex]) ),'"'));
       end else
       begin
           winopt.OpenFolder(ExtractFilePath(JvDotNetCheckListBox1.Items[JvDotNetCheckListBox1.ItemIndex]));   
       end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i: Integer;
  tmp: TStringList;
  temp: TstringList;
    Response: Integer;
begin
 Response := MessageDlg('Are you sure you want to remove this from startup?', mtConfirmation, [mbYes, mbNo], 0);
  if Response = mrYes then
    begin


     tmp:=TStringList.Create;
    winopt.ReadAllAutoStartKeys(tmp);
    temp:=TStringList.Create;
    
     for I := 0 to JvDotNetCheckListBox1.Count-1 do
      if JvDotNetCheckListBox1.Checked[i] then
            begin
                 temp.Clear;
                 temp.Delimiter:='\';
                 temp.DelimitedText := tmp.KeyNames[i];
                 winopt.DeleteRegistryValue(ExtractFilePath(tmp.KeyNames[i]),ExtractFileName(tmp.KeyNames[i]));
            end;
     tmp.Free;
     temp.free;
      winopt.LoadStringGrid(JvDotNetCheckListBox1);
             if JvDotNetCheckListBox1.count <= 0 then          
              JvNavPanelDivider1.Caption:='Empty'; 
    end
  else  begin                 
                 if JvDotNetCheckListBox1.count <= 0 then          
              JvNavPanelDivider1.Caption:='Empty';
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  i: Integer;
  tmp: TStringList;
  temp: TstringList;
    Response: Integer;
begin
     tmp:=TStringList.Create;
    winopt.ReadAllAutoStartKeys(tmp);
    temp:=TStringList.Create;
            begin
                 temp.Delimiter:='\';
                 temp.DelimitedText := tmp.KeyNames[JvDotNetCheckListBox1.ItemIndex];
                 winopt.RegJump(tmp.KeyNames[JvDotNetCheckListBox1.ItemIndex].Replace(ConCat('\',temp[temp.Count-1]),''));
                   
            end;
     tmp.Free;
     temp.free;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
   winopt.LoadStringGrid(JvDotNetCheckListBox1);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
   SaveDialog1.Filter := 'Backup Registry Files (*.reg.backup)|*.reg.backup'; 
   SaveDialog1.DefaultExt := 'reg.backup';
   SaveDialog1.FileName:='Backup-registry';
   
 if SaveDialog1.Execute then
        winopt.BackupAutoStartKeys(SaveDialog1.FileName);
end;

procedure TForm1.Button6Click(Sender: TObject);

begin
   OpenDialog1.Filter := 'Backup Registry Files (*.reg.backup)|*.reg.backup';
   OpenDialog1.DefaultExt := 'reg.backup';
   OpenDialog1.FileName:='Backup-registry';
//   FileOpenDialog1. := 'Backup Registry Files (*.reg.backup)|*.reg.backup';
    if OpenDialog1.Execute then
    begin
            winopt.RestoreAutoStartKeys(OpenDialog1.FileName);
            winopt.LoadStringGrid(JvDotNetCheckListBox1);  
             if JvDotNetCheckListBox1.count <= 0 then          
              JvNavPanelDivider1.Caption:='Empty';
    end;
end;

procedure TForm1.Button8Click(Sender: TObject);
var
  i,Response: integer;
begin
if JvDotNetCheckListBox2.ItemIndex >=0 then
begin
   Response := MessageDlg('Are you sure you want to remove this from startup?', mtConfirmation, [mbYes, mbNo], 0);
      if Response = mrYes then
      begin

          begin
          for I := 0 to JvDotNetCheckListBox2.Count-1 do
            if JvDotNetCheckListBox2.Checked[i] then
              winopt.UninstallUWPApp(JvDotNetCheckListBox2.Items[i]);
          end;
          end;
    end;
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
winopt.RunExecPid(ConCat(GetEnvironmentVariable('WINDIR'),'\system32\shutdown.exe -r -f -t 0'),false,false,false);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
winopt.LoadOptions;
linklabel3.Caption:= winopt.GetWindowsInfo;
end;

procedure TForm1.JvDotNetCheckListBox1Click(Sender: TObject);
var
    temp: TStringList;
begin
  if JvDotNetCheckListBox1.count > 0 then
  begin
      temp:=TstringList.Create;
      winopt.ReadAllAutoStartKeys(temp);
      JvNavPanelDivider1.Caption:=temp.KeyNames[JvDotNetCheckListBox1.ItemIndex];
      temp.Free;
  end else JvNavPanelDivider1.Caption:='Empty';
end;

procedure TForm1.JvDotNetCheckListBox1DblClick(Sender: TObject);
begin
  case  JvDotNetCheckListBox1.Checked[JvDotNetCheckListBox1.ItemIndex] of
      True: JvDotNetCheckListBox1.Checked[JvDotNetCheckListBox1.ItemIndex]:=False;
      False: JvDotNetCheckListBox1.Checked[JvDotNetCheckListBox1.ItemIndex]:=True;
  end;
end;

procedure TForm1.Label52Click(Sender: TObject);
begin
  winopt.setOption(53);
end;

procedure TForm1.ToggleSwitch10Click(Sender: TObject);
begin
 winopt.setOption(9);
end;

procedure TForm1.ToggleSwitch11Click(Sender: TObject);
begin
  winopt.setOption(10);
//  winopt.setOption(11);
end;

procedure TForm1.ToggleSwitch12Click(Sender: TObject);
begin
    winopt.setOption(12) ;
end;

procedure TForm1.ToggleSwitch13Click(Sender: TObject);
begin
    winopt.setOption(12);
end;

procedure TForm1.ToggleSwitch14Click(Sender: TObject);
begin
     winopt.setOption(13);
end;

procedure TForm1.ToggleSwitch15Click(Sender: TObject);
begin
    winopt.setOption(14);
end;

procedure TForm1.ToggleSwitch16Click(Sender: TObject);
begin
   winopt.setOption(15);
end;

procedure TForm1.ToggleSwitch17Click(Sender: TObject);
begin
     winopt.setOption(17);
end;

procedure TForm1.ToggleSwitch18Click(Sender: TObject);
begin
    winopt.setOption(18);
end;

procedure TForm1.ToggleSwitch19Click(Sender: TObject);
begin
winopt.setOption(18);
end;

procedure TForm1.ToggleSwitch1Click(Sender: TObject);
begin
    winopt.setOption(1);
end;

procedure TForm1.ToggleSwitch20Click(Sender: TObject);
begin
winopt.setOption(20);
end;

procedure TForm1.ToggleSwitch21Click(Sender: TObject);
begin
winopt.setOption(21);
end;

procedure TForm1.ToggleSwitch22Click(Sender: TObject);
begin
winopt.setOption(22);
end;

procedure TForm1.ToggleSwitch23Click(Sender: TObject);
begin
winopt.setOption(23);
end;

procedure TForm1.ToggleSwitch24Click(Sender: TObject);
begin
    winopt.setOption(24);
end;

procedure TForm1.ToggleSwitch25Click(Sender: TObject);
begin
winopt.setOption(25);
end;

procedure TForm1.ToggleSwitch26Click(Sender: TObject);
begin
winopt.setOption(26);
end;

procedure TForm1.ToggleSwitch27Click(Sender: TObject);
begin
winopt.setOption(27);
end;

procedure TForm1.ToggleSwitch28Click(Sender: TObject);
begin
winopt.setOption(28);
end;

procedure TForm1.ToggleSwitch29Click(Sender: TObject);
begin
winopt.setOption(29);
end;

procedure TForm1.ToggleSwitch2Click(Sender: TObject);
begin
 winopt.setOption(2);
end;

procedure TForm1.ToggleSwitch30Click(Sender: TObject);
begin
winopt.setOption(30);
end;

procedure TForm1.ToggleSwitch31Click(Sender: TObject);
begin
winopt.setOption(31);
end;

procedure TForm1.ToggleSwitch32Click(Sender: TObject);
begin
  winopt.setOption(32);
end;

procedure TForm1.ToggleSwitch33Click(Sender: TObject);
begin
 winopt.setOption(33);
end;

procedure TForm1.ToggleSwitch34Click(Sender: TObject);
begin
 winopt.setOption(34);
end;

procedure TForm1.ToggleSwitch35Click(Sender: TObject);
begin
 winopt.setOption(35);
end;

procedure TForm1.ToggleSwitch36Click(Sender: TObject);
begin
 winopt.setOption(36);
end;

procedure TForm1.ToggleSwitch37Click(Sender: TObject);
begin
 winopt.setOption(37);
end;

procedure TForm1.ToggleSwitch38Click(Sender: TObject);
begin
 winopt.setOption(38);
end;

procedure TForm1.ToggleSwitch39Click(Sender: TObject);
begin
 winopt.setOption(39);
end;

procedure TForm1.ToggleSwitch3Click(Sender: TObject);
begin
 winopt.setOption(3);
end;

procedure TForm1.ToggleSwitch40Click(Sender: TObject);
begin
 winopt.setOption(40);
end;

procedure TForm1.ToggleSwitch41Click(Sender: TObject);
begin
 winopt.setOption(41);
end;

procedure TForm1.ToggleSwitch42Click(Sender: TObject);
begin
   winopt.setOption(42);
end;

procedure TForm1.ToggleSwitch43Click(Sender: TObject);
begin
     winopt.setOption(43);
end;

procedure TForm1.ToggleSwitch44Click(Sender: TObject);
begin
winopt.setOption(44);
end;

procedure TForm1.ToggleSwitch45Click(Sender: TObject);
begin
winopt.setOption(45);
end;

procedure TForm1.ToggleSwitch46Click(Sender: TObject);
begin
winopt.setOption(46);
end;

procedure TForm1.ToggleSwitch47Click(Sender: TObject);
begin
winopt.setOption(47);
end;

procedure TForm1.ToggleSwitch48Click(Sender: TObject);
begin
winopt.setOption(48);
end;

procedure TForm1.ToggleSwitch49Click(Sender: TObject);
begin
winopt.setOption(49);
end;

procedure TForm1.ToggleSwitch4Click(Sender: TObject);
begin
 winopt.setOption(4);
end;

procedure TForm1.ToggleSwitch50Click(Sender: TObject);
begin
 winopt.setOption(50);
end;

procedure TForm1.ToggleSwitch51Click(Sender: TObject);
begin
  winopt.setOption(59);
end;

procedure TForm1.ToggleSwitch52Click(Sender: TObject);
begin
  winopt.setOption(51);
end;

procedure TForm1.ToggleSwitch53Click(Sender: TObject);
begin
  winopt.setOption(53);
end;

procedure TForm1.ToggleSwitch54Click(Sender: TObject);
begin
  winopt.setOption(52);
end;

procedure TForm1.ToggleSwitch55Click(Sender: TObject);
begin
    winopt.setOption(58);
end;

procedure TForm1.ToggleSwitch56Click(Sender: TObject);
begin
    winopt.setOption(57);
end;

procedure TForm1.ToggleSwitch57Click(Sender: TObject);
begin
    winopt.setOption(54);
end;

procedure TForm1.ToggleSwitch58Click(Sender: TObject);
begin
    winopt.setOption(55);
end;

procedure TForm1.ToggleSwitch59Click(Sender: TObject);
begin
   winopt.setOption(56);
end;

procedure TForm1.ToggleSwitch5Click(Sender: TObject);
begin
 winopt.setOption(5);
end;

procedure TForm1.ToggleSwitch60Click(Sender: TObject);
begin
winopt.setOption(60);
end;

procedure TForm1.ToggleSwitch61Click(Sender: TObject);
begin
winopt.setOption(61);
end;

procedure TForm1.ToggleSwitch62Click(Sender: TObject);
begin
winopt.setOption(62);
end;

procedure TForm1.ToggleSwitch63Click(Sender: TObject);
begin
winopt.setOption(63);
end;

procedure TForm1.ToggleSwitch67Click(Sender: TObject);
begin
winopt.setOption(67);
end;

procedure TForm1.ToggleSwitch68Click(Sender: TObject);
begin
winopt.setOption(68);
end;

procedure TForm1.ToggleSwitch69Click(Sender: TObject);
begin
winopt.setOption(69);
end;

procedure TForm1.ToggleSwitch6Click(Sender: TObject);
begin
 winopt.setOption(6);
end;

procedure TForm1.ToggleSwitch70Click(Sender: TObject);
begin
winopt.setOption(70);
end;

procedure TForm1.ToggleSwitch73Click(Sender: TObject);
begin
winopt.setOption(73);
end;

procedure TForm1.ToggleSwitch74Click(Sender: TObject);
begin
winopt.setOption(74);
end;

procedure TForm1.ToggleSwitch75Click(Sender: TObject);
begin
winopt.setOption(75);
end;

procedure TForm1.ToggleSwitch76Click(Sender: TObject);
begin
winopt.setOption(76);
end;

procedure TForm1.ToggleSwitch77Click(Sender: TObject);
begin
winopt.setOption(77);
end;

procedure TForm1.ToggleSwitch78Click(Sender: TObject);
begin
 winopt.setOption(78);
end;

procedure TForm1.ToggleSwitch79Click(Sender: TObject);
begin
winopt.setOption(79);
end;

procedure TForm1.ToggleSwitch7Click(Sender: TObject);
begin
 winopt.setOption(7);
end;

procedure TForm1.ToggleSwitch80Click(Sender: TObject);
begin
winopt.setOption(80);
end;

procedure TForm1.ToggleSwitch81Click(Sender: TObject);
begin
   winopt.setOption(81);
end;

procedure TForm1.ToggleSwitch82Click(Sender: TObject);
begin
   winopt.setOption(82);
end;

procedure TForm1.ToggleSwitch8Click(Sender: TObject);
begin
 winopt.setOption(8);
end;

procedure TForm1.ToggleSwitch9Click(Sender: TObject);
begin
   winopt.setOption(19);
end;

end.
