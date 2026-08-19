public with sharing class RestrictedPicklistReportController {

    public List <PicklistField> fields {get;set;}
    public String xlsHeader {
        get {
            String strHeader = '';
            strHeader += '<?xml version="1.0"?>';
            strHeader += '<?mso-application progid="Excel.Sheet"?>';
            return strHeader;
        }
    }
    
    public RestrictedPicklistReportController (){
        try {
            getPicklistFields();
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public void getPicklistFields() {
        List <EntityDefinition> entDefs = [SELECT Id, MasterLabel, Label, QualifiedApiName, NamespacePrefix FROM EntityDefinition];
        Map <String, String> masterLabelByAPI = new Map <String, String>();
        for (EntityDefinition entDef: entDefs) {
            masterLabelByAPI.put(entDef.QualifiedApiName, entDef.Label);
        }
        List <FieldDefinition> fieldDefs = [SELECT Id, EntityDefinition.QualifiedApiName, QualifiedApiName, DurableId FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName in: masterLabelByAPI.keySet()];
        Map <String, Map<String, String>> idByFieldAPIByObjectAPI = new Map <String, Map<String, String>>();
        for (FieldDefinition fieldDef: fieldDefs ) {
            if (idByFieldAPIByObjectAPI.containsKey(fieldDef.EntityDefinition.QualifiedApiName)) {
                idByFieldAPIByObjectAPI.get(fieldDef.EntityDefinition.QualifiedApiName).put(fieldDef.QualifiedApiName, fieldDef.DurableId );
            } else {
                Map<String, String> idByFieldAPI = new Map<String, String>();
                idByFieldAPI.put(fieldDef.QualifiedApiName, fieldDef.DurableId);
                idByFieldAPIByObjectAPI.put(fieldDef.EntityDefinition.QualifiedApiName, idByFieldAPI);
            }
        }
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        fields = new List <PicklistField >();
        //if only some of the objects needs to be included - use this set and uncomment condition with objectAPIs 
        Set <String> objectAPIs = new Set <String>{'CMPL123CME__Complaint__c', 'Trend_Item__c', 'CMPL123__Product__c', 'CMPL123__Contact__c', 'Product_Ticket__c',
                                                    'CMPL123CME__Investigation__c', 'Product_Lot__c', 'Task__c', 'Return__c', 'Customer_Response__c',
                                                    'CMPL123CME__Questionnaire__c', 'Reportability_History__c', 'Medical_Evaluation_Task__c', 'CMPL123CME__EMDR__c',
                                                    'CMPL123CME__Submission_History__c', 'CMPL123CME__MEDDEV__c'};
        List <Schema.SObjectType> gd = Schema.getGlobalDescribe().values();      
        Map<String, Schema.SObjectType> globalDescription = Schema.getGlobalDescribe();   
        for ( Schema.SObjectType obj : gd ) {  
            Schema.sObjectType objType = globalDescription.get(obj.getDescribe().getName() );
            if (obj.getDescribe().isCustom() && ! obj.getDescribe().isCustomSetting() && !obj.getDescribe().getName().endsWith('__mdt')){// && objectAPIs.contains(obj.getDescribe().getName())) {
                Schema.DescribeSObjectResult r1 = objType.getDescribe();   
                Map<String, Schema.SObjectField > mapFieldList = r1.fields.getMap(); 
                Map<String, Integer> fieldLabels = new Map<String, Integer>();
                String listFields = '';
                for ( Schema.SObjectField field : mapFieldList.values() ) {    
                    Schema.DescribeFieldResult fieldResult = field.getDescribe(); 
                    if (String.valueOf(fieldResult.getType()).containsIgnoreCase('Picklist')){
                        System.debug(String.valueOf(objType) + ': ' + fieldResult.getLabel() + ' ' + fieldResult);
                        String masterLabel = obj.getDescribe().getLabel();
                        /*if (masterLabelByAPI.containsKey(obj.getDescribe().getName())) {
                            masterLabel = masterLabelByAPI.get(obj.getDescribe().getName());
                        }*/
                        String fieldLink = baseUrl + '/';
                        if (idByFieldAPIByObjectAPI.containsKey(obj.getDescribe().getName()) && idByFieldAPIByObjectAPI.get(obj.getDescribe().getName()).containsKey(fieldResult.getName())) {
                            String durableId = idByFieldAPIByObjectAPI.get(obj.getDescribe().getName()).get(fieldResult.getName());
                            if (durableId.indexOf('.') != -1) {
                                fieldLink  += durableId.substring(durableId.indexOf('.')+1, durableId.length());
                            } else {
                                fieldLink  += durableId;
                            }
                        }
                        fields.add(new PicklistField (masterLabel , fieldLink,
                                                        obj.getDescribe().getName(), 
                                                        fieldResult.getLabel(), 
                                                        fieldResult.getName(), 
                                                        fieldResult.isRestrictedPicklist() ? 'Yes' : 'No'));      
                    }
                }
            }
        }
        fields.sort();     
    }

    public class PicklistField implements Comparable{
        public String obj {get;set;}
        public String Object_API {get;set;}
        public String fieldLink {get;set;}
        public String Picklist_Value_Name {get;set;}
        public String Picklist_Value_Name_API {get;set;}
        public String Restrict_Picklist_Values {get;set;}
        public PicklistField(String obj, String fieldLink, String Object_API, String Picklist_Value_Name, String Picklist_Value_Name_API, String Restrict_Picklist_Values){
            this.obj = obj;
            this.fieldLink  = fieldLink ;
            this.Object_API = Object_API;
            this.Picklist_Value_Name = Picklist_Value_Name;
            this.Picklist_Value_Name_API = Picklist_Value_Name_API;
            this.Restrict_Picklist_Values = Restrict_Picklist_Values;
        }
        public Integer compareTo(Object compareTo) {
            
            PicklistField compareToPF = (PicklistField )compareTo;
            if (obj > compareToPF.obj) {
                return 1;
            } else {
                return 0;
            }
        }
    }   
}