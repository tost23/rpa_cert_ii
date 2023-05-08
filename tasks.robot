*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.    


Library           RPA.Browser.Selenium    auto_close=${TRUE}
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.Tables
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download Orders and enter in website and store results in pdf
    [Teardown]    Close the browser



*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK


Download Orders and enter in website and store results in pdf
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Wait Until Page Contains Element    id:order-another
        Click Button    Order another robot
    END

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read Table From Csv    orders.csv    header=True
    RETURN    ${orders}



Fill the form
    [Arguments]    ${order}
    
    Select From List By Index    id=head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath=/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id=address    ${order}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    10 times    0.5 s    Click the Order Button    


    

Click the Order Button
    Click Button    Order
    Wait Until Page Contains    Receipt    0.5s
    Page Should Contain    Receipt


Store the receipt as a PDF file 
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:receipt
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${filepath}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    Html To Pdf    ${order_results_html}    ${filepath}
    RETURN    ${filepath}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${filepath}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}${order_number}.png
    Screenshot    id:robot-preview-image    ${filepath}
    RETURN    ${filepath}

Embed the robot screenshot to the receipt PDF file   
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}:x=50,y=100
    Add Files To Pdf    ${files}    ${pdf}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}
    ...    ${zip_file_name}
    ...    include=*.pdf

Close the browser
    Close Browser