const bookButton = document.getElementById("bookBtn");

bookButton.addEventListener("click", function () {
    const pickup = document.getElementById("pickup").value.trim();
    const drop = document.getElementById("drop").value.trim();
    const result = document.getElementById("result");

    if (!pickup || !drop) {
        result.textContent = "Please enter pickup and drop locations.";
        return;
    }

    const fare = Math.floor(Math.random() * 40) + 30;

    result.textContent =
        "Demo fare from " + pickup + " to " + drop + ": ₹" + fare;
});
