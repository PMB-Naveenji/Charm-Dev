/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : EMDRCustomException
* @Why   : Public class to handle all the custom exception related to EMDR..
* @When  : 23-11-2018
* @Where : From EMDRCustomException.cls (2 matches) Trigger
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin              23-11-2018         Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman                 25-Nov-2020            Charm Upgrade            Removed Picklist Value condition in Line no: 37.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
public class EMDRCustomException extends Exception {
    
    //Description: 
    
/**
* @Method       : patientDeviceCodeValidate
* @Invoke       : EMDRCustomException class
* @Description  : To check Device code and Patient code on Submit action
* @Return       : N/A
* @Params       : N/A
**/ 
    public static void patientDeviceCodeValidate(){
        
        String errorMessage = ''; 
        String emdrRecordId = ((CMPL123CME__EMDR__c)Trigger.New[0]).Id;
        Boolean deviceCodeAvailable = false;
        Boolean patientCodeAvailable = false;
        //for(CMPL123CME__MDR_Code__c objMDRCode : [SELECT CMPL123CME__EMDR_MDR_CODE_TYPE__c FROM CMPL123CME__MDR_Code__c  WHERE (CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'DEVICE CODE' OR CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'PATIENT CODE') AND CMPL123CME__EMDR__c =:emdrRecordId] ){
          //Start: Charm Upgrade - Lakshman  
          for(CMPL123CME__MDR_Code__c objMDRCode : [SELECT CMPL123CME__EMDR_MDR_CODE_TYPE__c FROM CMPL123CME__MDR_Code__c  WHERE (CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'DEVICE CODE' OR CMPL123CME__EMDR_MDR_CODE_TYPE__c = 'HEALTH EFFECT - CLINICAL CODE') AND CMPL123CME__EMDR__c =:emdrRecordId] ){
          //End: Charm Upgrade - Lakshman   
            
            if(deviceCodeAvailable && patientCodeAvailable ){
                break;
            }
            if(objMDRCode.CMPL123CME__EMDR_MDR_CODE_TYPE__c == AspenConstants.STR_Device_Code && deviceCodeAvailable != true){
                deviceCodeAvailable = true;
            }
            if(objMDRCode.CMPL123CME__EMDR_MDR_CODE_TYPE__c == 'HEALTH EFFECT - CLINICAL CODE' && patientCodeAvailable != true ){
                patientCodeAvailable = true;
            }
        } 
        
        errorMessage = deviceCodeAvailable == false  && patientCodeAvailable == false ? Label.EMDR_Device_code_and_Patient_code_error_message : deviceCodeAvailable == false ? Label.EMDR_Device_code_error_message : patientCodeAvailable == false ? Label.EMDR_Patient_code_error_message :'';
        if(errorMessage != ''){
            ((CMPL123CME__EMDR__c)Trigger.New[0]).addError(errorMessage);
        }
    } 
    
}