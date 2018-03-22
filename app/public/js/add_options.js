function updateOptionNames()
{
    var options = document.querySelector(".options");
    var i = 0;
    options.childNodes.forEach(e => {
        i++;
        e.placeholder = "Option " + i;
        e.name = "option_" + i;
    });
}

function addOptionListenerToElement(e)
{
    listener = function(event) {
        if(document.querySelector("input.option:last-child") == event.target)
        {
            //This was the last element, time to add a new option!
            if(event.target.value != "")
            {
                //Check so we actually did write something in the element
                var options = document.querySelector(".options")
                var option = document.createElement("input");
                option.classList.add("option");
                option.placeholder = "New Option...";
                addOptionListenerToElement(option);
                options.appendChild(option);
                updateOptionNames();
            }
        }
        else
        {
            //This was not the last element.
            if(event.target.value == "")
            {
                //Oh, it's empty. Let's remove it
                option_name = event.target.name
                event.target.parentNode.removeChild(event.target);
                updateOptionNames();
                document.querySelector(".option[name=\""+ option_name +"\"]").focus()
            }
        }
        if(event.target.value != "")
        {
            event.target.placeholder = "";
        }
    }
    e.addEventListener("keydown", listener);
    e.addEventListener("keyup", listener);
}

//At first there will only be one option.
document.querySelectorAll(".option").forEach(e => {
    addOptionListenerToElement(e);
});
