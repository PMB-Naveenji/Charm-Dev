/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : ObjectlevelPermissionsControllerDemo.
* @Why   : Generates Object Level Permissions xls.
* @When  : 26-FEB-2019.
* @Where : ObjectlevelPermissionsDemo.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    26-FEB-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit           Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class ObjectlevelPermissionsControllerDemo {
    public Transient List<wrapObjectPermissions> lstwrapObjectPermissions {get; set;}

    /*
    * @Constructor  : ObjectlevelPermissionsControllerDemo.
    * @Invoke       : Upon initialization of class.
    * @Description  : Runs logic upon initialization.
    * @Return       : Boolean.
    * @Params       : N/A.
    */
    public ObjectlevelPermissionsControllerDemo(){
        lstwrapObjectPermissions = New List<wrapObjectPermissions>();

        Map<String, Map<String, ObjectPermissions>> mapAllObjectPermissions = New Map<String, Map<String, ObjectPermissions>>();

        Set<Id> setCustomProfileIds = New Set<Id>();
        Set<Id> setCustomPermissionSetIds = New Set<Id>();
        Set<Id> setAllPermissionSetIds = New Set<Id>();

        Map<Id,String> mapPermissionSetNameIds = New Map<Id,String>();

        for(PermissionSet objPermissionSet : [SELECT Id, Name, ProfileId, Profile.Name, IsOwnedByProfile FROM PermissionSet
                                               WHERE isCustom = true ORDER BY ProfileId NULLS LAST, Name]){
            if(objPermissionSet.IsOwnedByProfile){
                setCustomProfileIds.add(objPermissionSet.ProfileId);
                mapPermissionSetNameIds.put(objPermissionSet.Id, objPermissionSet.Profile.Name+'(Profile)');
            }else{
                setCustomPermissionSetIds.add(objPermissionSet.Id);
                mapPermissionSetNameIds.put(objPermissionSet.Id, objPermissionSet.Name+'(PermissionSet)');
            }
        }

        for(ObjectPermissions objObjectPermission
            : [SELECT Id, SObjectType, ParentId, Parent.ProfileId, Parent.Profile.Name, PermissionsCreate,
               PermissionsRead, PermissionsEdit, PermissionsDelete,
               PermissionsModifyAllRecords,PermissionsViewAllRecords FROM ObjectPermissions WHERE parentId IN (SELECT Id FROM PermissionSet WHERE (PermissionSet.ProfileId IN: setCustomProfileIds OR PermissionSet.Id IN: setCustomPermissionSetIds))]){
                   Map<String, ObjectPermissions> mapTemp = New Map<String, ObjectPermissions>();
                   if(mapAllObjectPermissions.containsKey(objObjectPermission.SObjectType)){
                       mapTemp = mapAllObjectPermissions.get(objObjectPermission.SObjectType);
                   }
                   mapTemp.put(objObjectPermission.ParentId, objObjectPermission);
                   mapAllObjectPermissions.put(objObjectPermission.SObjectType, mapTemp);
               }

        wrapObjectPermissions objwrapObjectPermissionsHeader = New wrapObjectPermissions();
        objwrapObjectPermissionsHeader.strObjectName = 'Object';
        List<wrapPermissions> lstwrapPermissionsHeader = New List<wrapPermissions>();
        for(String strKey : mapPermissionSetNameIds.keySet()){
            wrapPermissions objwrapPermissionsHeader = New wrapPermissions();
            objwrapPermissionsHeader.strPermissionSetName = mapPermissionSetNameIds.get(strKey);
            objwrapPermissionsHeader.isPermissionsCreate = 'Create';
            objwrapPermissionsHeader.isPermissionsRead = 'Read';
            objwrapPermissionsHeader.isPermissionsEdit = 'Edit';
            objwrapPermissionsHeader.isPermissionsDelete = 'Delete';
            objwrapPermissionsHeader.isPermissionsModifyAllRecords = 'ModifyAll';
            objwrapPermissionsHeader.isPermissionsViewAllRecords = 'ViewAll';
            lstwrapPermissionsHeader.add(objwrapPermissionsHeader);
        }
        objwrapObjectPermissionsHeader.lstwrapPermissions = lstwrapPermissionsHeader;
        lstwrapObjectPermissions.add(objwrapObjectPermissionsHeader);

        for(String strObjectKey : mapAllObjectPermissions.keySet()){
            wrapObjectPermissions objwrapObjectPermissions = New wrapObjectPermissions();
            try{
                objwrapObjectPermissions.strObjectName = Schema.getGlobalDescribe().get(strObjectKey).getDescribe().getLabel();
            }catch(Exception E){
                system.debug('E' + E.getMessage());
                objwrapObjectPermissions.strObjectName = strObjectKey;
            }
            List<wrapPermissions> lstwrapPermissions = New List<wrapPermissions>();

            for(String strKey : mapPermissionSetNameIds.keySet()){
                ObjectPermissions objObjectPermissions = (mapAllObjectPermissions.get(strObjectKey).containsKey(strKey) && mapAllObjectPermissions.get(strObjectKey).get(strKey) != null) ? mapAllObjectPermissions.get(strObjectKey).get(strKey) : New ObjectPermissions();
                wrapPermissions objwrapPermissions = New wrapPermissions();

                objwrapPermissions.strPermissionSetName = '';
                objwrapPermissions.isPermissionsCreate = String.valueOf(objObjectPermissions.PermissionsCreate);
                objwrapPermissions.isPermissionsRead = String.valueOf(objObjectPermissions.PermissionsRead);
                objwrapPermissions.isPermissionsEdit = String.valueOf(objObjectPermissions.PermissionsEdit);
                objwrapPermissions.isPermissionsDelete = String.valueOf(objObjectPermissions.PermissionsDelete);
                objwrapPermissions.isPermissionsModifyAllRecords = String.valueOf(objObjectPermissions.PermissionsModifyAllRecords);
                objwrapPermissions.isPermissionsViewAllRecords = String.valueOf(objObjectPermissions.PermissionsViewAllRecords);
                lstwrapPermissions.add(objwrapPermissions);
            }
            objwrapObjectPermissions.lstwrapPermissions = lstwrapPermissions;
            lstwrapObjectPermissions.add(objwrapObjectPermissions);
        }
    }

    /*
    * @Class  : wrapObjectPermissions.
    * @Invoke       : N/A.
    * @Description  : Inner class wrapper.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public class wrapObjectPermissions{
        public String strObjectName {get; set;}
        public List<wrapPermissions> lstwrapPermissions {get; set;}
    }

    /*
    * @Class  : wrapPermissions.
    * @Invoke       : N/A.
    * @Description  : Inner class wrapper.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public class wrapPermissions {
        public String  strPermissionSetName {get; set;}
        public String isPermissionsCreate {get; set;}
        public String isPermissionsRead {get; set;}
        public String isPermissionsEdit {get; set;}
        public String isPermissionsDelete {get; set;}
        public String isPermissionsModifyAllRecords {get; set;}
        public String isPermissionsViewAllRecords {get; set;}
    }


}