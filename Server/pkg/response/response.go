package response

import "github.com/gin-gonic/gin"

func JSON(c *gin.Context, status int, payload any) {
	c.JSON(status, payload)
}

func Message(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"message": message})
}

func Error(c *gin.Context, status int, message string) {
	c.JSON(status, gin.H{"message": message})
}
