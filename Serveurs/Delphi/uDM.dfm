object dm: Tdm
  OnCreate = DataModuleCreate
  Height = 355
  Width = 766
  PixelsPerInch = 96
  object tabCourses: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 120
    Top = 40
    object tabCoursesproduit: TStringField
      FieldName = 'produit'
      Size = 50
    end
    object tabCoursesquantite: TIntegerField
      FieldName = 'quantite'
    end
  end
  object tabClients: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 40
    Top = 40
    object tabClientsid: TStringField
      FieldName = 'id'
      Size = 50
    end
  end
  object tabLogModifs: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 208
    Top = 40
    object tabLogModifssequence: TIntegerField
      FieldName = 'sequence'
    end
    object tabLogModifsid: TStringField
      FieldName = 'id'
      Size = 50
    end
    object tabLogModifsproduit: TStringField
      FieldName = 'produit'
      Size = 50
    end
    object tabLogModifsquantite: TIntegerField
      FieldName = 'quantite'
    end
  end
  object FDStanStorageBinLink1: TFDStanStorageBinLink
    Left = 120
    Top = 192
  end
end
