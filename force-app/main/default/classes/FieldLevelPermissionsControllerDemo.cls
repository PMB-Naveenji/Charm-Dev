/*
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : FieldLevelPermissionsControllerDemo.
* @Why   : Class to generate field level permission xls doc.
* @When  : 26-FEB-2019.
* @Where : From FieldLevelPermissionsDemo page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    26-FEB-2019            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                  Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    17-AUG-2020            Code Audit                  Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    08-SEP-2020            PMD Sanitizing              Added escaping of special sensitive symbols to url param.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class FieldLevelPermissionsControllerDemo {

    public Transient List<wrapFieldPermissions> lstwrapFieldPermissions {get; set;}
    public String strObjectName {get; set;}

    /*
    * @Constructor  : FieldLevelPermissionsControllerDemo.
    * @Description  : To execute logic upon class initialization.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public FieldLevelPermissionsControllerDemo(){
        // PMD Sanitizing: added escapeJava() method
        String strObjNameParam = apexpages.currentpage().getparameters().get('strObjectName');
        strObjectName = strObjNameParam != null ? strObjNameParam.escapeJava() : null;
        lstwrapFieldPermissions = New List<wrapFieldPermissions>();
        Map<String, Map<String, FieldPermissions>> mapAllFieldPermissions = New Map<String, Map<String, FieldPermissions>>();
        Map<String, String> mapFieldAPILabels = New Map<String, String>();
        Set<Id> setCustomProfileIds = New Set<Id>();
        Set<Id> setCustomPermissionSetIds = New Set<Id>();
        Set<Id> setAllPermissionSetIds = New Set<Id>();

        Schema.SObjectType objSObjectType = Schema.getGlobalDescribe().get(strObjectName);
        Map<String, Schema.SObjectField> mapSObjectField = Schema.getGlobalDescribe().get(strObjectName).getDescribe().fields.getMap();
        for(String strField : mapSObjectField.keySet()) {
            mapFieldAPILabels.put(strField.toLowerCase(),mapSObjectField.get(strField).getDescribe().getLabel());
        }
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
        for(FieldPermissions objFieldPermission : [SELECT
                                                   ParentId,
                                                   SObjectType,
                                                   Field,
                                                   PermissionsRead,
                                                   PermissionsEdit FROM FieldPermissions
                                                   WHERE parentId IN (SELECT Id FROM PermissionSet WHERE (PermissionSet.ProfileId IN: setCustomProfileIds OR PermissionSet.Id IN: setCustomPermissionSetIds)) AND SObjectType =: strObjectName ORDER BY SObjectType ASC, Parent.ProfileId NULLS LAST]){
                                                       Map<String, FieldPermissions> mapTemp = New Map<String, FieldPermissions>();
                                                       if(mapAllFieldPermissions.containsKey(objFieldPermission.Field)){
                                                           mapTemp = mapAllFieldPermissions.get(objFieldPermission.Field);
                                                       }
                                                       mapTemp.put(objFieldPermission.ParentId, objFieldPermission);
                                                       mapAllFieldPermissions.put(objFieldPermission.Field, mapTemp);
                                                   }
        wrapFieldPermissions objwrapFieldPermissionsHeader = New wrapFieldPermissions();
        objwrapFieldPermissionsHeader.strObjectName = 'Object';
        objwrapFieldPermissionsHeader.strFieldName = 'Field';

        List<wrapPermissions> lstwrapPermissionsHeader = New List<wrapPermissions>();
        for(String strKey : mapPermissionSetNameIds.keySet()){
            wrapPermissions objwrapPermissionsHeader = New wrapPermissions();
            objwrapPermissionsHeader.strPermissionSetName = mapPermissionSetNameIds.get(strKey);
            objwrapPermissionsHeader.isPermissionsRead = 'Read';
            objwrapPermissionsHeader.isPermissionsEdit = 'Edit';
            lstwrapPermissionsHeader.add(objwrapPermissionsHeader);
        }
        objwrapFieldPermissionsHeader.lstwrapPermissions = lstwrapPermissionsHeader;
        lstwrapFieldPermissions.add(objwrapFieldPermissionsHeader);

        for(String strFieldKey : mapAllFieldPermissions.keySet()){
            String strKeyTemp = strFieldKey;
            wrapFieldPermissions objwrapFieldPermissions = New wrapFieldPermissions();
            objwrapFieldPermissions.strObjectName = strFieldKey.substringBefore('.');
            objwrapFieldPermissions.strFieldName = strFieldKey.substringAfter('.');
            try{
                objwrapFieldPermissions.strObjectName = Schema.getGlobalDescribe().get(strFieldKey.substringBefore('.')).getDescribe().getLabel();
            }catch(Exception E){
                system.debug('E' + E.getMessage());
            }
            try{
                objwrapFieldPermissions.strFieldName = mapFieldAPILabels.get(strFieldKey.substringAfter('.').toLowerCase());
            }catch(Exception E){
                system.debug('E' + E.getMessage());
            }
            List<wrapPermissions> lstwrapPermissions = New List<wrapPermissions>();

            for(String strKey : mapPermissionSetNameIds.keySet()){
                FieldPermissions objFieldPermissions = (mapAllFieldPermissions.get(strFieldKey).containsKey(strKey) && mapAllFieldPermissions.get(strFieldKey).get(strKey) != null) ? mapAllFieldPermissions.get(strFieldKey).get(strKey) : New FieldPermissions();
                wrapPermissions objwrapPermissions = New wrapPermissions();

                objwrapPermissions.strPermissionSetName = '';
                objwrapPermissions.isPermissionsRead = String.valueOf(objFieldPermissions.PermissionsRead);
                objwrapPermissions.isPermissionsEdit = String.valueOf(objFieldPermissions.PermissionsEdit);
                lstwrapPermissions.add(objwrapPermissions);
            }
            objwrapFieldPermissions.lstwrapPermissions = lstwrapPermissions;
            lstwrapFieldPermissions.add(objwrapFieldPermissions);
        }
    }

    public class wrapFieldPermissions {
        public String strObjectName {get; set;}
        public String strFieldName {get; set;}
        public List<wrapPermissions> lstwrapPermissions {get; set;}
    }

    public class wrapPermissions {
        public String  strPermissionSetName {get; set;}
        public String isPermissionsRead {get; set;}
        public String isPermissionsEdit {get; set;}
    }

}