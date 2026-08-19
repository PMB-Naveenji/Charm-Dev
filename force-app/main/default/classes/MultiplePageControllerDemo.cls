/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MultiplePageControllerDemo.
* @Why   : To run FieldLevelPermissionsDemo page.
* @When  : 26-FEB-2019.
* @Where : From MultiplePageDemo page.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    26-FEB-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MultiplePageControllerDemo{
    public Integer count {get;set;}
    private List<String> lstObjectNames = New List<String>();

    /*
    * @Constructor  : MultiplePageControllerDemo.
    * @Description  : Runs logic upon class initialization.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public MultiplePageControllerDemo() {
        count = -1;
        for(Schema.SObjectType objType : Schema.getGlobalDescribe().Values()){
            String strObjectName = objType.getDescribe().getName();
            if(!strObjectName.containsignorecase('history') && !strObjectName.containsignorecase('tag')&&
               !strObjectName.containsignorecase('share') && !strObjectName.containsignorecase('feed')){
                   lstObjectNames.add(objType.getDescribe().getName());
               }
        }
        lstObjectNames.sort();
    }

    /*
    * @Constructor  : incrementCounter.
    * @Description  : Runs FieldLevelPermissionsDemo page.
    * @Invoke       : From MultiplePageDemo page.
    * @Return       : FieldLevelPermissionsDemo PageReference.
    * @Params       : N/A.
    */
    public PageReference incrementCounter() {
        if(count < lstObjectNames.size()){
            PageReference objPageReference = Page.FieldLevelPermissionsDemo;
            objPageReference.getParameters().put('strObjectName',lstObjectNames[count]);
            objPageReference.setRedirect(false);
            return objPageReference;
        }else{
            return null;
        }
    }

}