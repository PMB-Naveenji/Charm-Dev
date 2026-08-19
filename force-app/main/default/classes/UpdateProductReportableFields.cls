/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : UpdateProductReportableFields.
* @Why   : W-001387 - To update all related product field when W.F Action is completed.
* @When  : 23-MAR-2017.
* @Where : From ADDMedEvalTaskTriggerHandler class, MedicalEvaluationTaskTriggerHandler class.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  23-MAR-2017            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class UpdateProductReportableFields{
    /*
    * @Method       : updateFields.
    * @Description  : Upon Complete action, the system will auto populate the Reportable fields in all products in RCML Task - Product.
    * @Invoke       : From ADDMedEvalTaskTriggerHandler Class, MedicalEvaluationTaskTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Medical_Evaluation_Task__c> medicalEvalTaskList.
    */
    public void updateFields(List<Medical_Evaluation_Task__c> medicalEvalTaskList){
        List<CMPL123__Product__c> productToBeUpdated = new List<CMPL123__Product__c>();
        Set<String> productIdSet = new Set<String>();
        for(RCML_Task_Product__c product:[SELECT RCML_Task_ID__c,Product_ID__c FROM RCML_Task_Product__c
                                            WHERE RCML_Task_ID__c IN:medicalEvalTaskList
                                            AND Product_ID__c!= Null]){
            productIdSet.add(product.Product_ID__c);
        }
        if(productIdSet.size()>0){
           for(CMPL123__Product__c prod:[SELECT Reportable_Confirmed_Malfunction_List__c,
                                          Reportable_Confirmed_Malfunction_Descrip__c,
                                          Reportable_Confirmed_MalfunctionInitDate__c
                                          FROM CMPL123__Product__c WHERE Id IN:productIdSet]){
                for(Medical_Evaluation_Task__c medTask:medicalEvalTaskList){
                    if (medTask.Add_Confirmed_Malfunction_to_RCML_List__c == 'Yes') {
                        //Defect 1531 fix BEGIN
                        //'TRUE' -> 'Yes'
                        prod.Reportable_Confirmed_Malfunction_List__c = 'Yes';
                        //Defect 1531 fix END
                        //Added W-000571 (Removed from no)
                        prod.Reportable_Confirmed_Malfunction_Descrip__c = medTask.Reportable_Confirmed_Malfunction_Descrip__c;
                        prod.Reportable_Confirmed_MalfunctionInitDate__c = System.now();
                    } else{
                         prod.Reportable_Confirmed_Malfunction_List__c = '';
                         prod.Reportable_Confirmed_Malfunction_Descrip__c = '';
                         prod.Reportable_Confirmed_MalfunctionInitDate__c = null;
                    }

                    productToBeUpdated.add(prod);
                }
            }
        }
        if(productToBeUpdated.size()>0){
            update productToBeUpdated;
        }
    }

    /*
    * @Method       : validationRuleCheck.
    * @Description  : Upon Complete action, the system will check if at least one record in the RCML Task else throw error.
    * @Invoke       : From ADDMedEvalTaskTriggerHandler Class, MedicalEvaluationTaskTriggerHandler class.
    * @Return       : N/A.
    * @Params       : List<Medical_Evaluation_Task__c> medicalEvalTaskList.
    */
    public void validationRuleCheck(List<Medical_Evaluation_Task__c> medicalEvalTaskList){
        List<RCML_Task_Product__c> RCMLTaskProdList = [SELECT RCML_Task_ID__c,Product_ID__c FROM RCML_Task_Product__c
                                                        WHERE RCML_Task_ID__c IN:medicalEvalTaskList
                                                         AND Product_ID__c!= Null];
        if(RCMLTaskProdList == Null || RCMLTaskProdList.size() == 0){
          for(Medical_Evaluation_Task__c prod:medicalEvalTaskList){
            prod.addError(System.label.Medical_Evaluation_Task_Product_Required);
          }
        }
    }
}