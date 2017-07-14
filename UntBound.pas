unit UntBound;

interface

uses
  Generics.Collections, System.Bindings.Expression, System.Bindings.Helper, VCL.Forms,
  Classes, RTTI, TypInfo,Vcl.StdCtrls, Vcl.DBCtrls, CxCalendar,
  System.Bindings.ExpressionDefaults, UntClassesRegistradas,Vcl.ExtCtrls, System.Threading,
  System.Bindings.Outputs, UntConverter;

type
  TypeTimer = (ttObject, ttControls);

  TBoundObject = class
    procedure OnGetTimer(Sender: Tobject);
    procedure OnSetTimer(Sender: Tobject);
  protected
    type
      TExpressionList = TObjectList<TBindingExpression>;
  private
    FBindings: TExpressionList;
    fTimer : TTimer;
    fDictObjectBound : TDictionary<TObject,TList<string>>;
    fDictComponentBound : TDictionary<TObject,TList<string>>;
    function GetRegisteredProperty(pComponent: TClass): string;
    procedure CreateTimer(pTypeTimer: TypeTimer; interval: Cardinal);
    procedure ClearBindings;
  protected
    property Bindings: TExpressionList read FBindings;
  public
    class var RttiContext : TRttiContext;
    constructor Create; overload;
    constructor Create(pTypeTimer: TypeTimer; interval: Cardinal); overload;
    destructor Destroy; override;
    procedure Notify(const pObj : TObject ; const APropertyName: string = '');
    procedure Bind(const pObj : TObject ;const AProperty: string; const ABindToObject: TObject;
        const ABindToProperty: string;
        const ACreateOptions: TBindings.TCreateOptions = [coNotifyOutput, coEvaluate]);  overload;

    procedure Bind(const pObj : TObject ; const Prop: TRttiProperty; const ABindToObject: TObject;
        const ABindProp: TRttiProperty;
        const ACreateOptions: TBindings.TCreateOptions = [coNotifyOutput, coEvaluate]); overload;

    procedure BindAll(const pObj : TObject ; const pComponent: TComponent;
        const ACreateOptions: TBindings.TCreateOptions = [coNotifyOutput, coEvaluate]); overload;
     procedure BindAll(const pObj : TObject ; const pObjF: TObject;
        const ACreateOptions: TBindings.TCreateOptions = [coNotifyOutput, coEvaluate]); overload;
    procedure NotifyObjects;
    procedure NotifyControls;
  end;

implementation

constructor TBoundObject.Create;
begin
  inherited Create;
  FBindings := TExpressionList.Create(false {AOwnsObjects});
  fDictObjectBound := TDictionary<TObject,TList<string>>.Create;
  fDictComponentBound := TDictionary<TObject,TList<string>>.Create;
  fTimer := TTimer.Create(nil);
  fTimer.Enabled := False;
  RttiContext := TRttiContext.Create;
end;

constructor TBoundObject.Create(pTypeTimer: TypeTimer; interval: Cardinal);
begin
  inherited Create;
  FBindings := TExpressionList.Create(false {AOwnsObjects});
  fDictObjectBound := TDictionary<TObject,TList<string>>.Create;
  fDictComponentBound := TDictionary<TObject,TList<string>>.Create;
  CreateTimer(pTypeTimer, interval);
  RttiContext := TRttiContext.Create;

end;

destructor TBoundObject.Destroy;
begin
  ClearBindings;
  FBindings.Free;
  fDictObjectBound.Free;
  fDictComponentBound.Free;
  fTimer.Free;
  inherited;
end;

procedure TBoundObject.CreateTimer(pTypeTimer: TypeTimer; interval: Cardinal);
begin
  fTimer := TTimer.Create(nil);
  fTimer.Interval := interval;

  case pTypeTimer of
    ttObject: fTimer.OnTimer := OnGetTimer;
    ttControls: fTimer.OnTimer := OnSetTimer;
  end;

  fTimer.Enabled := True;
end;

procedure TBoundObject.BindAll(const pObj: TObject;
  const pComponent: TComponent; const ACreateOptions: TBindings.TCreateOptions);
var
  RttiType: TRttiType;
  RttiType2: TRttiType;
  Prop: TRttiProperty;
  Prop2 : TRttiProperty;
  FComponent: TComponent;
  i : integer;
begin
  RttiType := RttiContext.GetType(pObj.ClassType);

  for Prop in RttiType.GetProperties do
  begin
    if Prop.Visibility <> TMemberVisibility.mvPublished then
      Continue;

    FComponent := pComponent.FindComponent(Prop.Name);

    if FComponent <> nil then
      Bind(pObj, Prop.Name, FComponent, GetRegisteredProperty(FComponent.ClassType));

  end;

end;

function TBoundObject.GetRegisteredProperty(pComponent : TClass): string;
begin
  try
    Result := ListaClassesRegistradas.Items[pComponent];
  except
    Result := 'Text';

  end;

end;

procedure TBoundObject.Bind(const pObj: TObject; const Prop: TRttiProperty;
  const ABindToObject: TObject; const ABindProp: TRttiProperty;
  const ACreateOptions: TBindings.TCreateOptions);
begin

  if fDictObjectBound.ContainsKey(pobj) then
  begin
    fDictObjectBound.Items[pObj].Add(Prop.Name);
  end
  else
  begin
    fDictObjectBound.Add(pObj, Tlist<string>.Create);
    fDictObjectBound.Items[pObj].Add(Prop.Name);
  end;

  // From source to dest
  FBindings.Add(TBindings.CreateManagedBinding(
      { inputs }
      [TBindings.CreateAssociationScope([Associate(pObj, 'src')])],
      'src.' + Prop.Name,
      { outputs }
      [TBindings.CreateAssociationScope([Associate(ABindToObject, 'dst')])],
      'dst.' + ABindProp.Name,
      Converter.Conversions , nil, ACreateOptions));

  // From dest to source
  if fDictComponentBound.ContainsKey(ABindToObject) then
  begin
    fDictComponentBound.Items[ABindToObject].Add(ABindProp.Name);
  end
  else
  begin
    fDictComponentBound.Add(ABindToObject, Tlist<string>.Create);
    fDictComponentBound.Items[ABindToObject].Add(ABindProp.Name);
  end;

  FBindings.Add(TBindings.CreateManagedBinding(
      { inputs }
      [TBindings.CreateAssociationScope([Associate(ABindToObject, 'src')])],
      'src.' + ABindProp.Name,
      { outputs }
      [TBindings.CreateAssociationScope([Associate(pObj, 'dst')])],
      'dst.' + Prop.Name,
      Converter.Conversions, nil, ACreateOptions));

end;

procedure TBoundObject.BindAll(const pObj, pObjF: TObject;
  const ACreateOptions: TBindings.TCreateOptions);
var
  RttiType: TRttiType;
  Prop: TRttiProperty;
  FComponent: TComponent;
begin
  RttiType := RttiContext.GetType(pObj.ClassType);

  for Prop in RttiType.GetProperties do
  begin
    if Prop.Visibility <> TMemberVisibility.mvPublished then
      Continue;

    Bind(pObj, Prop.Name, pObjF, Prop.Name);

  end;

end;

procedure TBoundObject.ClearBindings;
var
  i: TBindingExpression;
begin
  for i in FBindings do
    TBindings.RemoveBinding(i);
  FBindings.Clear;
end;

procedure TBoundObject.Notify(const pObj : TObject ; const APropertyName: string);
begin
  TBindings.Notify(pObj, APropertyName);
end;

procedure TBoundObject.Bind(const pObj : TObject ;const AProperty: string;
  const ABindToObject: TObject; const ABindToProperty: string;
  const ACreateOptions: TBindings.TCreateOptions);
begin
  if fDictObjectBound.ContainsKey(pobj) then
  begin
    fDictObjectBound.Items[pObj].Add(AProperty);
  end
  else
  begin
    fDictObjectBound.Add(pObj, Tlist<string>.Create);
    fDictObjectBound.Items[pObj].Add(AProperty);
  end;

  // From source to dest
  FBindings.Add(TBindings.CreateManagedBinding(
      { inputs }
      [TBindings.CreateAssociationScope([Associate(pObj, 'src')])],
      'src.' + AProperty,
      { outputs }
      [TBindings.CreateAssociationScope([Associate(ABindToObject, 'dst')])],
      'dst.' + ABindToProperty,
      Converter.Conversions , nil, ACreateOptions));

  // From dest to source
  if fDictComponentBound.ContainsKey(ABindToObject) then
  begin
    fDictComponentBound.Items[ABindToObject].Add(ABindToProperty);
  end
  else
  begin
    fDictComponentBound.Add(ABindToObject, Tlist<string>.Create);
    fDictComponentBound.Items[ABindToObject].Add(ABindToProperty);
  end;

  FBindings.Add(TBindings.CreateManagedBinding(
      { inputs }
      [TBindings.CreateAssociationScope([Associate(ABindToObject, 'src')])],
      'src.' + ABindToProperty,
      { outputs }
      [TBindings.CreateAssociationScope([Associate(pObj, 'dst')])],
      'dst.' + AProperty,
      Converter.Conversions, nil, ACreateOptions));

end;

procedure TBoundObject.NotifyObjects;
var
  o: Tobject;
  i: integer;
begin
  for o in fDictObjectBound.Keys do
    begin
      for I := 0 to fDictObjectBound.Items[o].Count -1 do
        begin
          Notify(o, fDictObjectBound.Items[o].Items[i]);
        end;

    end;

end;

procedure TBoundObject.OnGetTimer(Sender: Tobject);
var
  task : ITask;
begin
  NotifyObjects;
end;

procedure TBoundObject.OnSetTimer(Sender: Tobject);
var
  task : ITask;
begin
  NotifyControls;
end;

procedure TBoundObject.NotifyControls;
var
  o: Tobject;
  i: integer;
begin
  for o in fDictComponentBound.Keys do
    begin
      for I := 0 to fDictComponentBound.Items[o].Count -1 do
        begin
          Notify(o, fDictComponentBound.Items[o].Items[i]);
        end;

    end;

end;


end.
