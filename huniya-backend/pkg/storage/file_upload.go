package storage

import (
	"errors"
	"fmt"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"huniya-backend/config"

	"github.com/gin-gonic/gin"
)

const MaxFilesAllowed = 5

var allowedExtensions = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

func SaveUploadedImages(c *gin.Context, files []*multipart.FileHeader) ([]string, error) {
	if len(files) == 0 {
		return []string{}, nil
	}

	if len(files) > MaxFilesAllowed {
		return nil, fmt.Errorf("maksimal unggahan adalah %d foto per properti", MaxFilesAllowed)
	}

	cfg := config.AppConfig
	maxBytes := cfg.MaxUploadMB * 1024 * 1024

	if err := os.MkdirAll(cfg.UploadDir, os.ModePerm); err != nil {
		return nil, errors.New("gagal membuat direktori penyimpanan foto")
	}

	var savedPaths []string
	for idx, file := range files {
		if file.Size > maxBytes {
			return nil, fmt.Errorf("ukuran file %s melebihi batas maksimal %dMB", file.Filename, cfg.MaxUploadMB)
		}

		ext := strings.ToLower(filepath.Ext(file.Filename))
		if !allowedExtensions[ext] {
			return nil, fmt.Errorf("format file %s tidak didukung (gunakan JPG atau PNG)", file.Filename)
		}

		filename := fmt.Sprintf("prop_%d_%d%s", time.Now().UnixNano(), idx, ext)
		destPath := filepath.Join(cfg.UploadDir, filename)

		if err := c.SaveUploadedFile(file, destPath); err != nil {
			return nil, fmt.Errorf("gagal menyimpan file %s: %v", file.Filename, err)
		}

		savedPaths = append(savedPaths, "/uploads/"+filename)
	}

	return savedPaths, nil
}
