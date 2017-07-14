unit UntClassesRegistradas;

interface

uses
  SysUtils, Classes, StdCtrls, Controls,dxBarExtDBItems,
  VclTee.TeCanvas, cxClasses, Windows,ExtCtrls, Generics.Collections,
  DBCtrls;

type
  TListaClassesRegistradas = class(TDictionary<TClass, String>)
    procedure RegistrarClasse(pClasse: TClass; pProp: String);
  end;

  var
    ListaClassesRegistradas : TListaClassesRegistradas;
implementation

procedure TListaClassesRegistradas.RegistrarClasse(pClasse: TClass;
  pProp: String);
begin
  if Self.ContainsKey(pClasse) then
    exit;

  Self.Add(pClasse, pProp);
end;

initialization
  ListaClassesRegistradas := TListaClassesRegistradas.Create;
  ListaClassesRegistradas.RegistrarClasse(TEdit , 'Text');
  ListaClassesRegistradas.RegistrarClasse(TDBEdit , 'Text');
  ListaClassesRegistradas.RegistrarClasse(TDBLookupComboBox , 'KeyValue');
  ListaClassesRegistradas.RegistrarClasse(TMemo , 'Lines');
  ListaClassesRegistradas.RegistrarClasse(TDBMemo , 'Lines');
  ListaClassesRegistradas.RegistrarClasse(TDBCheckBox , 'Checked');
  ListaClassesRegistradas.RegistrarClasse(TCheckBox , 'Checked');
  ListaClassesRegistradas.RegistrarClasse(TLabel , 'Caption');
  ListaClassesRegistradas.RegistrarClasse(TPanel , 'Caption');
end.
