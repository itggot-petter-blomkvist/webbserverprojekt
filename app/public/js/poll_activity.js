var canvases = document.querySelectorAll(".poll_activity")

canvases.forEach(function (c) {
    var ctx = c.getContext("2d")
    ctx.moveTo(0,0)
    ctx.lineTo(200,100)
    ctx.lineWidth = 2
    ctx.strokeStyle = '#00ff00'
    ctx.stroke()
})