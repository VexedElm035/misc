class mainScene{
    preload(){
        
        this.load.image('player', 'assets/player.png');
        this.load.image('coin', 'assets/player.png');
    }
    create(){
        this.player = this.physics.add.sprite(100, 100, 'player');
        this.coin = this.physics.add.sprite(300, 300, 'coin');
        this.score= 0;
        this.scoretext = this.add.text(10, 10, 'score: ' + this.score);
        this.arrow = this.input.keyboard.createCursorKeys();
    }
    update(){
        if (this.physics.overlap(this.player, this.coin)) {
            this.hit();
        }
        if (this.arrow.right.isDown) {
            this.player.x += 3;
        } else if (this.arrow.left.isDown) {
            this.player.x -= 3;
        }
        if (this.arrow.down.isDown) {
            this.player.y += 3;
        } else if (this.arrow.up.isDown) {
            this.player.y -= 3;
        }
    }
    hit() {
        this.coin.x = Phaser.Math.Between(0, 400);
        this.coin.y = Phaser.Math.Between(0, 400);
        this.score += 1;
        this.scoretext.setText('score: ' + this.score);
        this.tweens.add({
            targets: this.player,
            duration: 200, //200ms
            scaleX: 1.2,
            scaleY: 1.2,
            yoyo: true, //get back to original size
        });
    }
}

new Phaser.Game({
    width: 400,
    height: 400,
    backgroundColor: '#b1b1b1ff',
    scene: mainScene,
    physics: {default: 'arcade'},
    parent: 'game',
})