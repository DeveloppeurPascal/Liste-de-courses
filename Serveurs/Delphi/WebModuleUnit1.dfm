object WebModule1: TWebModule1
  Actions = <
    item
      Default = True
      Name = 'DefaultHandler'
      PathInfo = '/'
      OnAction = WebModule1DefaultHandlerAction
    end
    item
      MethodType = mtGet
      Name = 'IdentificationClient'
      PathInfo = '/register'
      OnAction = WebModule1IdentificationClientAction
    end
    item
      MethodType = mtPost
      Name = 'EnvoiDesModifications'
      PathInfo = '/courses'
      OnAction = WebModule1EnvoiDeModificationsAction
    end
    item
      MethodType = mtGet
      Name = 'ChargementDesModification'
      PathInfo = '/courses'
      OnAction = WebModule1ChargementDesModificationAction
    end>
  Height = 230
  Width = 415
end
