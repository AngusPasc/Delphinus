object CategoryFilterView: TCategoryFilterView
  Left = 0
  Top = 0
  Width = 320
  Height = 240
  TabOrder = 0
  OnResize = FrameResize
  object tvCategories: TTreeView
    Left = 0
    Top = 0
    Width = 320
    Height = 105
    Align = alTop
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    HideSelection = False
    HotTrack = True
    Indent = 19
    ParentColor = True
    ParentFont = False
    RowSelect = True
    ShowButtons = False
    ShowLines = False
    TabOrder = 0
    OnAdvancedCustomDrawItem = tvCategoriesAdvancedCustomDrawItem
    OnChange = tvCategoriesChange
    OnCollapsing = tvCategoriesCollapsing
  end
end
