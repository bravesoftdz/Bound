unit UntConverter;

interface

uses
  Generics.Collections, Classes, SysUtils, Variants, VarUtils, StrUtils, Math,
  System.Bindings.Outputs, Rtti, TypInfo, Data.Bind.Components, VCL.Forms;

type

  TConversor = class(TPersistent)
    private
      Bindinglist : TCustomBindingsList;
      fConversions : IValueRefConverter;
    public
      property Conversions: IValueRefConverter read fConversions write fConversions;
      constructor Create;

  end;

  var
    Converter : TConversor;

implementation

{ TConversor }

constructor TConversor.Create;
begin
  inherited Create;
  Bindinglist := TCustomBindingsList.Create(Application);
  Conversions := TValueRefConverter.Create;
  Conversions := Bindinglist.GetOutputConverter;
end;

initialization
  Converter := TConversor.Create;

end.
