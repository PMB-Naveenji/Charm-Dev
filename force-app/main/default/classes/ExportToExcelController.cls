/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ExportToExcelController.
* @Why   : Generated CWB tabs FieldDefinition, FieldPermission
* @When  : 28-SEP-2020.
* @Where : From ExportToExcel VF page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                   28-SEP-2020            CWB tabs generation         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public with sharing class ExportToExcelController {
    
    public String xlsName {get;set;}
    public Map<Integer, FieldPermission> data { get; private set; }
    public List <Field> fields {get;set;}
    public Map <String, String> requiredFields;
    public Map <String, String> autoNumberFields;
    public Map <String, String> masterLabelByAPI;
    public Datetime lastModifiedDateForStObject {get;set;}
    public String lastModifiedByForStObject {get;set;}
    public Map <String, Datetime> lastModifiedDateByFieldApi;
    public String xlsHeader {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0" encoding="UTF-8"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    
    public ExportToExcelController (){
       try {
            xlsName = ApexPages.currentPage().getParameters().get('xlsName');
            //for standard fields of custom objects
            EntityDefinition entDef = [SELECT Id, LastModifiedDate, LastModifiedBy.Name, QualifiedApiName FROM EntityDefinition where QualifiedApiName =: xlsName];
            lastModifiedByForStObject = String.valueOf(entDef.LastModifiedBy.Name);
            lastModifiedDateForStObject = entDef.LastModifiedDate; 
            //for standard fields of standard objects
            if (lastModifiedByForStObject == null || lastModifiedByForStObject == null){
                Organization org = [SELECT Id, Name, LastModifiedDate, CreatedDate, CreatedById, LastModifiedBy.Name FROM Organization limit 1];
                lastModifiedByForStObject = String.valueOf(org.LastModifiedBy.Name);
                lastModifiedDateForStObject = org.LastModifiedDate; 
            }
      } catch (Exception e) {
          System.debug(e.getMessage());
      }
    }
    
    /*
    * @Method       : generateData.
    * @Description  : To generate 2 tabs for CWB.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void generateData () {
        getFieldDefinitions();
        getFieldPermissions(); 
    }
    
    /*
    * @Method       : generateData.
    * @Description  : To generate FieldPermission tab for CWB.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void getFieldPermissions () {
        try {
            data = new Map<Integer, FieldPermission>();
            Set <String> profileNames = new Set <String>{'ASPEN', 'System Administrator Data Loader', 'System Administrator', 'Aspen User', 'ASPEN Integration'};
            Set <String> permToSkip = new Set <String>{'X123Compliance_Permission_Set_for_Platform_User', 'X123Compliance_Permission_Set_User', 
                            'X123Compliance_Permission_Set', 'User_Access_Permission', 'Complaint_App_Permission_Set_Platform_User_License', 'Complaint_App_Permission_Set_for_Platform_User', 
                            'Complaint_App_Permission_Set_User', 'Complaint_App_Permission_Set'};
            List <FieldPermissions> fieldPermissions = [Select Id, ParentId, Parent.Name, Parent.Profile.Name, Parent.ProfileId, SobjectType, Field, PermissionsEdit, PermissionsRead, SystemModstamp 
                                            From FieldPermissions 
                                            Where SobjectType =: xlsName
                                            //and (Parent.ProfileId = null or Parent.Profile.Name in :profileNames) 
                                            and (Parent.License.Name = 'Salesforce Platform' or Parent.License.Name = 'Salesforce')
                                           // and Parent.Name not in : permToSkip 
                                            order by Parent.Profile.Name, Parent.Name, Field];
            Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();  
            Schema.sObjectType objType = globalDescription.get(xlsName);  
            Map<String, Schema.SObjectField> mapFieldList = objType.getDescribe().fields.getMap();    
            Map <String, String> labelByAPI = new Map <String, String>();
            List <FieldPermission> allFieldPermissions = new  List <FieldPermission> ();
            requiredFields = new Map <String, String>();
            autoNumberFields = new Map <String, String>();
            for (Schema.SObjectField fieldDesc: mapFieldList.values()) {
                if ( fieldDesc.getDescribe().getLabel() == '') {
                    labelByAPI.put(fieldDesc.getDescribe().getLocalName(), fieldDesc.getDescribe().getLocalName());
                } else {
                    labelByAPI.put(fieldDesc.getDescribe().getLocalName(), fieldDesc.getDescribe().getLabel());
                }
                if ((fieldDesc.getDescribe().isCreateable() 
                        && !fieldDesc.getDescribe().isNillable() 
                        && !fieldDesc.getDescribe().isDefaultedOnCreate()) 
                    || fieldDesc.getDescribe().isNameField() ) {
                        requiredFields.put(fieldDesc.getDescribe().getLocalName(), fieldDesc.getDescribe().getLabel());
                }
                if (fieldDesc.getDescribe().getLocalName() == 'OwnerId') {
                    requiredFields.put(fieldDesc.getDescribe().getLocalName(), 'Owner');
                }
                if (fieldDesc.getDescribe().isAutoNumber()) {
                    autoNumberFields.put(fieldDesc.getDescribe().getLocalName(), fieldDesc.getDescribe().getLabel());
                }
                
            }
            
            System.debug(LoggingLevel.ERROR, requiredFields);
            List <PermissionSet> permSets = [Select Id, Name, ProfileId, Profile.Name from PermissionSet 
                                            where //(ProfileId = null or Profile.Name in :profileNames) and
                                            (License.Name = 'Salesforce Platform' or License.Name = 'Salesforce')
                                            //and Name not in: permToSkip 
                                            ];
            List <FieldPermission> perms = new List <FieldPermission >();
            
            for (FieldPermissions fieldPerm: fieldPermissions ) {
                String apiReceived= fieldPerm.Field.replace(xlsName+'.', '');
                String masterLabel = labelByAPI.get(apiReceived);
                if (masterLabelByAPI.containsKey(apiReceived)) {
                    masterLabel = masterLabelByAPI.get(apiReceived);
                }
                String dateTimeStr = fieldPerm.SystemModstamp.format('yyyy-MM-dd HH:mm:ss.000+0000', 'Europe/London') ;
                allFieldPermissions.add(new FieldPermission (masterLabel, xlsName, String.valueOf(fieldPerm.Id), 
                                        fieldPerm.Parent.ProfileId != null ? fieldPerm.Parent.Profile.Name : '-' , 
                                        String.valueOf((fieldPerm.Parent.ProfileId == null || fieldPerm.Parent.Name.contains('00ex')) ? fieldPerm.Parent.Name : '-'), 
                                        String.valueOf(fieldPerm.Field.replace(xlsName + '.', '')), String.valueOf(fieldPerm.PermissionsEdit).toUpperCase(), 
                                        String.valueOf(fieldPerm.PermissionsRead).toUpperCase(), dateTimeStr ));
                
            }
            for (PermissionSet permSet : permSets) {
                for (String api: requiredFields.keySet()){
                    String masterLabel = requiredFields.get(api);
                    
                    if (masterLabelByAPI.containsKey(api)) {
                        masterLabel = masterLabelByAPI.get(api);
                    }
                    String dateTimeStr ;
                    if (lastModifiedDateByFieldApi.get(api) == null) {
                        dateTimeStr = lastModifiedDateForStObject.format('yyyy-MM-dd HH:mm:ss.000+0000', 'Europe/London');
                    } else {
                        dateTimeStr = lastModifiedDateByFieldApi.get(api).format('yyyy-MM-dd HH:mm:ss.000+0000', 'Europe/London');
                    }
                    
                    allFieldPermissions.add(new FieldPermission (masterLabel, xlsName, String.valueOf(permSet.Id), 
                                            permSet.ProfileId != null ? permSet.Profile.Name : '-' , 
                                            String.valueOf((permSet.ProfileId == null || permSet.Name.contains('00ex'))? permSet.Name : '-'), 
                                            api, 
                                            autoNumberFields.containsKey(api) ? 'FALSE' : 'TRUE', 
                                            'TRUE', 
                                            dateTimeStr));
                    
                }
            }
            allFieldPermissions.sort();
            Integer i = 0;
            for (FieldPermission fp: allFieldPermissions ) {
                data.put(i, fp);
                i++;
            }
            
        } catch(Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            System.debug(e.getMessage());
        }
    }
    
    /*
    * @Method       : generateData.
    * @Description  : To generate FieldDefinition tab for CWB.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public void getFieldDefinitions () {
        try {
            masterLabelByAPI = new Map <String, String>();
            List <Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();      
            Map<String , Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();   
            List <Schema.SObjectField> fieldsDesc = new List <Schema.SObjectField>();
            List <FieldDefinition> fds = [SELECT Id, QualifiedApiName, MasterLabel, DataType, Label, LastModifiedDate, LastModifiedBy.Name 
                                        FROM FieldDefinition 
                                        WHERE EntityDefinition.QualifiedApiName =: xlsName];
            Map <String, FieldDefinition> fieldDefinitionByName = new  Map <String, FieldDefinition>();
            for (FieldDefinition fieldDef: fds) {
                fieldDefinitionByName.put(fieldDef.QualifiedApiName, fieldDef);
            }
            Schema.sObjectType objType = globalDescription.get(xlsName);  
            Map<String , Schema.SObjectField > mapFieldList = objType.getDescribe().fields.getMap();    
            fieldsDesc = mapFieldList.values();
            
            fields = new List <Field>();
            List <CMPL123__AuditTrail_Config__c> auditTrails= [SELECT CMPL123__Child_Relationships_Object__c, CMPL123__Fields__c, CMPL123__Is_Active__c, CMPL123__Parent_Relationship_Object__c 
                        FROM CMPL123__AuditTrail_Config__c
                        WHERE Name =: xlsName and CMPL123__Is_Active__c = true];
            lastModifiedDateByFieldApi = new Map <String, DateTime>();
            for (Schema.SObjectField  fieldDesc: fieldsDesc) {
                Schema.DescribeFieldResult dfr = fieldDesc.getDescribe();
                if (dfr.isCustom()){ 
                    Field f = new Field();
                    f.apiName = dfr.getLocalName();
                    f.fieldName = fieldDefinitionByName.get(f.apiName).MasterLabel;
                    masterLabelByAPI.put(f.apiName, f.fieldName);
                    f.auditTrail = 'FALSE';
                    if (auditTrails.size() > 0 && auditTrails.get(0).CMPL123__Fields__c.contains(f.apiName)) {
                        f.auditTrail = 'TRUE';
                    }
                    f.dataType = fieldDefinitionByName.get(f.apiName).DataType;//String.valueOf(dfr.getType()).toLowerCase().capitalize();
                    if (f.dataType.contains('Formula') && f.dataType.indexOf('(') != -1) {
                      
                        f.dataType = f.dataType.substring(f.dataType.indexOf('(')+1, f.dataType.indexOf(')'));
                    } else if (f.dataType.indexOf('(') != -1) {
                        f.dataType = f.dataType.substring(0, f.dataType.indexOf('('));
                    }
                    
                    if (String.valueOf(dfr.getType()) == 'MULTIPICKLIST') {
                        f.dataType = 'MultiselectPicklist';
                    }
                    
                    f.length = String.valueOf(dfr.getLength());
                    f.formulas = '-';
                    
                    if (dfr.getCalculatedFormula() != null && dfr.getCalculatedFormula() != '') {
                        f.formulas = dfr.getCalculatedFormula().replace('<', '&lt;').replace('>', '&gt;');
                    }
                   
                    f.defaultValue = '-';
                    if (dfr.getDefaultValue() != null) {
                       f.defaultValue = String.valueOf(dfr.getDefaultValue()).toUpperCase();
                    }
                    f.required = String.valueOf(dfr.isCreateable() && !dfr.isNillable() && !dfr.isDefaultedOnCreate()).toUpperCase();
                    f.unique = String.valueOf(dfr.isUnique()).toUpperCase();
                    if (fieldDefinitionByName.containsKey(f.apiName)) {
                        f.lastModifiedDate = fieldDefinitionByName.get(f.apiName).LastModifiedDate.format('yyyy-MM-dd HH:mm:ss.000+0000', 'Europe/London');
                        f.lastModifiedName = fieldDefinitionByName.get(f.apiName).LastModifiedBy.Name;
                        lastModifiedDateByFieldApi.put(f.apiName, fieldDefinitionByName.get(f.apiName).LastModifiedDate);
                    }
                    f.lastModifiedDate = overwriteLastModifiedDate(f.lastModifiedDate);
                    f.lastModifiedName = overwriteLastModifiedBy(f.lastModifiedName);
                    
                    f.referenceObject = '-';
                    for (Schema.SObjectType refer: dfr.getReferenceTo()) {
                        f.referenceObject = String.valueOf(refer);
                    }
                    f.picklistValues = '';
                    for (Schema.PicklistEntry picklist: dfr.getPicklistValues()) {
                        f.picklistValues += picklist.getLabel() + ' ';
                    }
                    fields.add(f);
                }
            }
            fields.sort();
           
        } catch(Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            System.debug(e.getMessage());
        }
    }
    public String overwriteLastModifiedDate (Object value) {
        if (value == null || value == '-' || value == '') {
            return lastModifiedDateForStObject.format('yyyy-MM-dd HH:mm:ss.000+0000', 'Europe/London');
        }
        return String.valueOf(value);
    }
    public String overwriteLastModifiedBy(Object value) {
        if (value == null || value == '-') {
            return lastModifiedByForStObject;
        }
        return String.valueOf(value);
    }
    
    public class FieldPermission implements Comparable {
        
        public String name {get;set;}
        public String objectName {get;set;}
        public String permsetProfile {get;set;}
        public String parentName {get;set;}
        public String field {get;set;}
        public String fieldLabel {get;set;}
        public String permissionsEdit {get;set;} 
        public String permissionsRead {get;set;}
        public String systemModstamp {get;set;}
        
        public FieldPermission  (String fieldLabel, String objectName, String name, String permsetProfile, String parentName, String field, String permissionsEdit, String permissionsRead, String systemModstamp) {
            this.objectName = objectName;
            this.name = name;
            this.permsetProfile = permsetProfile;
            this.parentName = parentName;
            this.field = field;
            this.fieldLabel = fieldLabel;
            this.permissionsEdit = permissionsEdit ;
            this.permissionsRead = permissionsRead ;
            this.systemModstamp = systemModstamp ;
        }
        
        public Integer compareTo(Object objToCompare) {
            return parentName.compareTo(((FieldPermission)objToCompare).parentName);
        }
    }
    
    public class Field implements Comparable {
        
        public String fieldName {get;set;}
        public String apiName   {get;set;}
        public String dataType  {get;set;}
        public String length    {get;set;}
        public String defaultValue  {get;set;}
        public String required  {get;set;}
        public String unique    {get;set;}
        public String formulas  {get;set;}
        public String picklistValues    {get;set;}
        public String referenceObject   {get;set;}
        public String auditTrail {get;set;}
        public String lastModifiedDate  {get;set;}
        public String lastModifiedName  {get;set;}
        
        public Field() {

        }
        
        public Integer compareTo(Object objToCompare) {
            return fieldName.compareTo(((Field)objToCompare).fieldName);
        }
    }
}