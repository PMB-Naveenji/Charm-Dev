/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : GetFieldLabelAPI.
* @Why   : Inserts AllCustomObjectFieldLabelInDEVIQ csv with Object Name, ObjectAPI, FieldLabel, FieldAPI, Type columns.
* @When  : 11-JUL-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    11-JUL-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit           Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    18-AUG-2020            Code Audit           Adjusted class/methods headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class GetFieldLabelAPI {

    /*
    * @Method       : requiredFieldsFromsObject.
    * @Description  : Inserts AllCustomObjectFieldLabelInDEVIQ csv with Object Name, ObjectAPI, FieldLabel, FieldAPI, Type columns.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void requiredFieldsFromsObject(){
        String csvBody = 'Object Name,ObjectAPI,FieldLabel,FieldAPI,Type\n';
        for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();

            if(objResult.getName().contains('__c') && objResult.isCreateable()){
                Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe() ;
                Schema.SObjectType s = m.get(objResult.getName()) ;
                Schema.DescribeSObjectResult r = s.getDescribe() ;
                Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
                List<String> lstrequiredfields=new List<String>();

                for(String f : fields.keyset())
                {
                    Schema.DescribeFieldResult desribeResult = fields.get(f).getDescribe();
                    csvBody += objResult.getLabel()+','+objResult.getName()+','+desribeResult.getLabel()+','+desribeResult.getName()+','+desribeResult.getType()+'\n';
                }
            }
        }

        Document d = new Document();
        d.Body = Blob.valueof(csvBody);
        d.Name = 'AllCustomObjectFieldLabelInDEVIQ.csv';
        d.FolderId = '00536000002Q8Vn';
        INSERT d;
    }
}