class Tower extends iio.Shape
    constructor: (grid, io, x, y, width, range, rv=false)->
        this.rangevisible = rv
        this.grid = grid
        this.width = width
        this.range = range
        cellPos = this.grid.getCellCenter(x,y)
        this.img = new iio.Rect(cellPos.x + (this.width-1)*10, cellPos.y + (this.width-1)*10, this.width*20).setStrokeStyle("black")
        this.styles = this.img.styles
        
        this.rangeIndicator = new iio.Circle(cellPos.x + (this.width-1)*10, cellPos.y + (this.width-1)*10, this.range * 20)
                                    .setStrokeStyle("rgba(0,0,0,0.2)")
                                    .setLineWidth(3)
                                    .setFillStyle("rgba(200,200,200,0.1)")
        if !this.rangevisible
            this.rangeIndicator.setAlpha(0)
        io.addObj(this.rangeIndicator)
        this.setPos(x, y)

    toggleRangeIndicator: ->
        this.rangevisible != this.rangevisible
        this.rangeIndicator.setAlpha(this.rangevisible ? 1 : 0)
        
    setPos: (x,y)->
        super
        this.unmarkBuilding()

        cellPos = this.grid.getCellCenter(x,y)
        this.img.setPos(cellPos.x + (this.width-1)*10, cellPos.y + (this.width-1)*10)
        this.rangeIndicator.setPos(cellPos.x + (this.width-1)*10, cellPos.y + (this.width-1)*10)

        this.markBuilding(x,y)
        return

    markBuilding: (x,y)->
        minX = Math.max(x, 0)
        minY = Math.max(y, 0)
        maxX = Math.min(x+this.width-1, 49)
        maxY = Math.min(y+this.width-1, 29)
        for _x in [minX .. maxX]
            for _y in [minY .. maxY]
                this.grid.cells[_x][_y].building = this
        return

    unmarkBuilding: ->
        oldCellPos = this.grid.getCellAt(this.img.pos, true)
        minX = Math.max(oldCellPos.x, 0)
        minY = Math.max(oldCellPos.y, 0)
        maxX = Math.min(oldCellPos.x+this.width-1, 49)
        maxY = Math.min(oldCellPos.y+this.width-1, 29)
        for _x in [ minX .. maxX]
            for _y in [minY .. maxY]
                this.grid.cells[_x][_y].building = null
        return

    draw: ->
        this.img.draw.apply(this.img, arguments)
        this.rangeIndicator.draw.apply(this.img, arguments)


class TempTower extends Tower
    markBuilding: ->
    unmarkBuilding: ->

class BaseTower extends Tower
    constructor: ->
        super
        this.img.setFillStyle("navy")

class NormalTower extends Tower
    constructor: ->
        super
        this.img.setFillStyle("lightblue")


class Checkpoint extends iio.Obj
    constructor: (x, y)->
        this.setPos(x, y)





class Game
    constructor: (io)->
        this.io = io

        this.createGrid(io)
        this.setupGrid(io)



        this.buildMode = true

        this.setupMouse(io)

        this.towers = []
        io.addGroup("towers", 10)

        this.baseTower = new BaseTower(this.grid, io, 46,12,7,9)
        io.addToGroup("towers",this.baseTower)

        io.setFramerate(60)

    createGrid: (io)->
        this.grid = new iio.Grid(0,0,50,30,20)
                        .setStrokeStyle("rgba(40, 20, 128, 0.5)")
                        .setLineWidth(1)
        io.addGroup("grid", -1)
        io.addToGroup("grid",this.grid)
    setupGrid: (io)->
        this.checkpoints = []
        io.addGroup("checkpoints", -21)
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(1, 5)))
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(10, 5)))
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(10, 25)))
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(20, 25)))
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(20, 15)))
        io.addToGroup("checkpoints" ,this.checkpoints.push(new Checkpoint(45, 15)))

        points = []
        for i in this.checkpoints
            points.push this.grid.getCellCenter(i.pos)

        io.addGroup("overlays", -20)
        for i in [0..this.checkpoints.length-2]
            vertical = this.checkpoints[i].pos.x - this.checkpoints[i+1].pos.x == 0

            if(vertical)
                for y in [this.checkpoints[i].pos.y-1 .. this.checkpoints[i+1].pos.y+1]
                    for dx in [-1..1]
                        continue if this.grid.cells[this.checkpoints[i].pos.x + dx][y].unbuildable
                        this.grid.cells[this.checkpoints[i].pos.x + dx][y].unbuildable = true
                        cellPos = this.grid.getCellCenter(this.checkpoints[i].pos.x + dx, y)
                        io.addToGroup("overlays", new iio.Rect(cellPos.x, cellPos.y, 10)
                                                            .setFillStyle("blanchedalmond")
                                                            .setStrokeStyle("rgb(155, 135, 105)"))

            else
                for x in [this.checkpoints[i].pos.x-1 .. this.checkpoints[i+1].pos.x+1]
                    for dy in [-1..1]
                        continue if this.grid.cells[x][this.checkpoints[i].pos.y + dy].unbuildable
                        this.grid.cells[x][this.checkpoints[i].pos.y + dy].unbuildable = true
                        cellPos = this.grid.getCellCenter(x, this.checkpoints[i].pos.y + dy)
                        io.addToGroup("overlays", new iio.Rect(cellPos.x, cellPos.y, 10)
                                                            .setFillStyle("blanchedalmond")
                                                            .setStrokeStyle("rgb(155, 135, 105)"))


        io.addToGroup("checkpoints",new iio.MultiLine(points).setStrokeStyle("red").setLineWidth(1), "checkpoints")

    setupMouse: (io)->
        this.tempTurret = new TempTower(this.grid,io,10,10,2,4,true)
        this.tempTurret.img.setFillStyle("green").setAlpha(0.6)
        io.addToGroup("overlays", this.tempTurret)


        io.canvas.addEventListener( "mousemove", (e)=>
            if(this.tempTurret.styles.alpha == 0 && this.buildMode)
                this.tempTurret.setAlpha(0.5)
            else if(this.tempTurret.styles.alpha != 0 && this.buildMode)
                pos = this.grid.getCellAt(io.getEventPosition(e),true)
                this.tempTurret.setPos(pos.x, pos.y)
                buildable = !!!this.grid.cells[pos.x][pos.y].unbuildable || !!!this.grid.cells[pos.x][pos.y].building
                for i in [0..this.tempTurret.width-1]
                    if(this.grid.cells[pos.x + i][pos.y].unbuildable || !!this.grid.cells[pos.x + i][pos.y].building)
                        buildable = false
                    if(this.grid.cells[pos.x][pos.y + i].unbuildable || !!this.grid.cells[pos.x][pos.y + i].building)
                        buildable = false
                    if(this.grid.cells[pos.x + i][pos.y + i].unbuildable || !!this.grid.cells[pos.x + i][pos.y + i].building)
                        buildable = false
                if(buildable)
                    this.tempTurret.buildable = true
                    this.tempTurret.img.setFillStyle("green")
                else
                    this.tempTurret.buildable = false
                    this.tempTurret.img.setFillStyle("red")
        )
        io.canvas.addEventListener "mousedown", (e)=>
            if(this.tempTurret.buildable)
                tower = new NormalTower(this.grid, io, this.tempTurret.pos.x, this.tempTurret.pos.y, 2, 4)
                io.addToGroup("towers", tower)
                this.towers.push tower
                this.tempTurret.buildable = false

    setBuildMode: (mode)->
        this.buildMode = mode


$(->
    game = null
    iio.start((io)->
        game = new Game(io)
    , "gameCanvas")
)
