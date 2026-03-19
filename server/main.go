package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	_ "github.com/mattn/go-sqlite3"
	"golang.org/x/crypto/bcrypt"
)

var db *sql.DB
var jwtSecret = []byte("your-secret-key") // In production, use env var

type User struct {
	ID           string `json:"id"`
	Email        string `json:"email"`
	PasswordHash string `json:"-"`
	Name         string `json:"name"`
}

type Budget struct {
	ID             string          `json:"id"`
	UserID         string          `json:"user_id"`
	StartDate      time.Time       `json:"start_date"`
	EndDate        time.Time       `json:"end_date"`
	Incomes        []IncomeItem    `json:"incomes"`
	CategoryGroups []CategoryGroup `json:"category_groups"`
}

type IncomeItem struct {
	ID             string  `json:"id"`
	BudgetID       string  `json:"budget_id"`
	Name           string  `json:"name"`
	PlannedAmount  float64 `json:"planned_amount"`
	ReceivedAmount float64 `json:"received_amount"`
}

type CategoryGroup struct {
	ID       string         `json:"id"`
	BudgetID string         `json:"budget_id"`
	Name     string         `json:"name"`
	Items    []CategoryItem `json:"items"`
}

type CategoryItem struct {
	ID            string  `json:"id"`
	GroupID       string  `json:"group_id"`
	Name          string  `json:"name"`
	PlannedAmount float64 `json:"planned_amount"`
	SpentAmount   float64 `json:"spent_amount"`
}

func main() {
	var err error
	db, err = sql.Open("sqlite3", "./budget.db")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	initDB()

	mux := http.NewServeMux()

	// Auth routes
	mux.HandleFunc("/api/register", registerHandler)
	mux.HandleFunc("/api/login", loginHandler)

	// Protected routes
	mux.Handle("/api/budgets", authMiddleware(http.HandlerFunc(budgetsHandler)))
	mux.Handle("/api/budgets/", authMiddleware(http.HandlerFunc(budgetDetailHandler)))
	
	mux.Handle("/api/incomes", authMiddleware(http.HandlerFunc(incomesHandler)))
	mux.Handle("/api/incomes/", authMiddleware(http.HandlerFunc(incomeDetailHandler)))

	mux.Handle("/api/groups", authMiddleware(http.HandlerFunc(groupsHandler)))
	mux.Handle("/api/groups/", authMiddleware(http.HandlerFunc(groupDetailHandler)))

	mux.Handle("/api/items", authMiddleware(http.HandlerFunc(itemsHandler)))
	mux.Handle("/api/items/", authMiddleware(http.HandlerFunc(itemDetailHandler)))

	log.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", mux))
}

func initDB() {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			email TEXT UNIQUE NOT NULL,
			password_hash TEXT NOT NULL,
			name TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS budgets (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			start_date DATETIME NOT NULL,
			end_date DATETIME NOT NULL,
			FOREIGN KEY(user_id) REFERENCES users(id)
		);`,
		`CREATE TABLE IF NOT EXISTS incomes (
			id TEXT PRIMARY KEY,
			budget_id TEXT NOT NULL,
			name TEXT NOT NULL,
			planned_amount REAL NOT NULL,
			received_amount REAL NOT NULL,
			FOREIGN KEY(budget_id) REFERENCES budgets(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS category_groups (
			id TEXT PRIMARY KEY,
			budget_id TEXT NOT NULL,
			name TEXT NOT NULL,
			FOREIGN KEY(budget_id) REFERENCES budgets(id) ON DELETE CASCADE
		);`,
		`CREATE TABLE IF NOT EXISTS category_items (
			id TEXT PRIMARY KEY,
			group_id TEXT NOT NULL,
			name TEXT NOT NULL,
			planned_amount REAL NOT NULL,
			spent_amount REAL NOT NULL,
			FOREIGN KEY(group_id) REFERENCES category_groups(id) ON DELETE CASCADE
		);`,
	}

	for _, q := range queries {
		_, err := db.Exec(q)
		if err != nil {
			log.Fatal(err)
		}
	}
}

// Auth Logic
func authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		userID := claims["user_id"].(string)
		r.Header.Set("X-User-ID", userID)
		next.ServeHTTP(w, r)
	})
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Name     string `json:"name"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	id := uuid.New().String()

	_, err := db.Exec("INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)", id, req.Email, string(hash), req.Name)
	if err != nil {
		http.Error(w, "Email already exists", http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var user User
	err := db.QueryRow("SELECT id, email, password_hash, name FROM users WHERE email = ?", req.Email).Scan(&user.ID, &user.Email, &user.PasswordHash, &user.Name)
	if err != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"exp":     time.Now().Add(time.Hour * 72).Unix(),
	})

	tokenString, _ := token.SignedString(jwtSecret)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"token": tokenString,
		"user":  user,
	})
}

// Budget Handlers
func budgetsHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")

	if r.Method == http.MethodGet {
		rows, err := db.Query("SELECT id, start_date, end_date FROM budgets WHERE user_id = ?", userID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		budgets := []Budget{}
		for rows.Next() {
			var b Budget
			rows.Scan(&b.ID, &b.StartDate, &b.EndDate)
			budgets = append(budgets, b)
		}
		json.NewEncoder(w).Encode(budgets)
	} else if r.Method == http.MethodPost {
		var b Budget
		if err := json.NewDecoder(r.Body).Decode(&b); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		b.ID = uuid.New().String()
		tx, err := db.Begin()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		_, err = tx.Exec("INSERT INTO budgets (id, user_id, start_date, end_date) VALUES (?, ?, ?, ?)", b.ID, userID, b.StartDate, b.EndDate)
		if err != nil {
			tx.Rollback()
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		for _, inc := range b.Incomes {
			incID := uuid.New().String()
			_, err = tx.Exec("INSERT INTO incomes (id, budget_id, name, planned_amount, received_amount) VALUES (?, ?, ?, ?, ?)", incID, b.ID, inc.Name, inc.PlannedAmount, inc.ReceivedAmount)
			if err != nil {
				tx.Rollback()
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
		}

		for _, g := range b.CategoryGroups {
			groupID := uuid.New().String()
			_, err = tx.Exec("INSERT INTO category_groups (id, budget_id, name) VALUES (?, ?, ?)", groupID, b.ID, g.Name)
			if err != nil {
				tx.Rollback()
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			for _, item := range g.Items {
				itemID := uuid.New().String()
				_, err = tx.Exec("INSERT INTO category_items (id, group_id, name, planned_amount, spent_amount) VALUES (?, ?, ?, ?, ?)", itemID, groupID, item.Name, item.PlannedAmount, item.SpentAmount)
				if err != nil {
					tx.Rollback()
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
			}
		}

		err = tx.Commit()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(b)
	}
}

func budgetDetailHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	budgetID := strings.TrimPrefix(r.URL.Path, "/api/budgets/")

	// Verify ownership
	var b Budget
	err := db.QueryRow("SELECT id, start_date, end_date FROM budgets WHERE id = ? AND user_id = ?", budgetID, userID).Scan(&b.ID, &b.StartDate, &b.EndDate)
	if err != nil {
		http.Error(w, "Budget not found", http.StatusNotFound)
		return
	}

	if r.Method == http.MethodGet {
		// Load incomes
		rows, _ := db.Query("SELECT id, name, planned_amount, received_amount FROM incomes WHERE budget_id = ?", budgetID)
		for rows.Next() {
			var inc IncomeItem
			rows.Scan(&inc.ID, &inc.Name, &inc.PlannedAmount, &inc.ReceivedAmount)
			b.Incomes = append(b.Incomes, inc)
		}
		rows.Close()

		// Load groups and items
		rows, _ = db.Query("SELECT id, name FROM category_groups WHERE budget_id = ?", budgetID)
		for rows.Next() {
			var g CategoryGroup
			rows.Scan(&g.ID, &g.Name)
			
			itemRows, _ := db.Query("SELECT id, name, planned_amount, spent_amount FROM category_items WHERE group_id = ?", g.ID)
			for itemRows.Next() {
				var i CategoryItem
				itemRows.Scan(&i.ID, &i.Name, &i.PlannedAmount, &i.SpentAmount)
				g.Items = append(g.Items, i)
			}
			itemRows.Close()
			b.CategoryGroups = append(b.CategoryGroups, g)
		}
		rows.Close()

		json.NewEncoder(w).Encode(b)
	} else if r.Method == http.MethodDelete {
		db.Exec("DELETE FROM budgets WHERE id = ?", budgetID)
		w.WriteHeader(http.StatusNoContent)
	}
}

// Income Handlers
func incomesHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var inc IncomeItem
	json.NewDecoder(r.Body).Decode(&inc)

	// Verify budget ownership
	var count int
	db.QueryRow("SELECT count(*) FROM budgets WHERE id = ? AND user_id = ?", inc.BudgetID, userID).Scan(&count)
	if count == 0 {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	inc.ID = uuid.New().String()
	_, err := db.Exec("INSERT INTO incomes (id, budget_id, name, planned_amount, received_amount) VALUES (?, ?, ?, ?, ?)", inc.ID, inc.BudgetID, inc.Name, inc.PlannedAmount, inc.ReceivedAmount)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(inc)
}

func incomeDetailHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	incomeID := strings.TrimPrefix(r.URL.Path, "/api/incomes/")

	// Verify ownership through budget
	var budgetUserID string
	err := db.QueryRow("SELECT b.user_id FROM budgets b JOIN incomes i ON b.id = i.budget_id WHERE i.id = ?", incomeID).Scan(&budgetUserID)
	if err != nil || budgetUserID != userID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	if r.Method == http.MethodPatch {
		var req IncomeItem
		json.NewDecoder(r.Body).Decode(&req)
		_, err := db.Exec("UPDATE incomes SET name = ?, planned_amount = ?, received_amount = ? WHERE id = ?", req.Name, req.PlannedAmount, req.ReceivedAmount, incomeID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	} else if r.Method == http.MethodDelete {
		db.Exec("DELETE FROM incomes WHERE id = ?", incomeID)
		w.WriteHeader(http.StatusNoContent)
	}
}

// Group Handlers
func groupsHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var g CategoryGroup
	json.NewDecoder(r.Body).Decode(&g)

	// Verify budget ownership
	var count int
	db.QueryRow("SELECT count(*) FROM budgets WHERE id = ? AND user_id = ?", g.BudgetID, userID).Scan(&count)
	if count == 0 {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	g.ID = uuid.New().String()
	_, err := db.Exec("INSERT INTO category_groups (id, budget_id, name) VALUES (?, ?, ?)", g.ID, g.BudgetID, g.Name)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(g)
}

func groupDetailHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	groupID := strings.TrimPrefix(r.URL.Path, "/api/groups/")

	// Verify ownership
	var budgetUserID string
	err := db.QueryRow("SELECT b.user_id FROM budgets b JOIN category_groups g ON b.id = g.budget_id WHERE g.id = ?", groupID).Scan(&budgetUserID)
	if err != nil || budgetUserID != userID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	if r.Method == http.MethodPatch {
		var req CategoryGroup
		json.NewDecoder(r.Body).Decode(&req)
		db.Exec("UPDATE category_groups SET name = ? WHERE id = ?", req.Name, groupID)
		w.WriteHeader(http.StatusNoContent)
	} else if r.Method == http.MethodDelete {
		db.Exec("DELETE FROM category_groups WHERE id = ?", groupID)
		w.WriteHeader(http.StatusNoContent)
	}
}

// Item Handlers
func itemsHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var i CategoryItem
	json.NewDecoder(r.Body).Decode(&i)

	// Verify group ownership
	var budgetUserID string
	err := db.QueryRow("SELECT b.user_id FROM budgets b JOIN category_groups g ON b.id = g.budget_id WHERE g.id = ?", i.GroupID).Scan(&budgetUserID)
	if err != nil || budgetUserID != userID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	i.ID = uuid.New().String()
	_, err = db.Exec("INSERT INTO category_items (id, group_id, name, planned_amount, spent_amount) VALUES (?, ?, ?, ?, ?)", i.ID, i.GroupID, i.Name, i.PlannedAmount, i.SpentAmount)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(i)
}

func itemDetailHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-ID")
	itemID := strings.TrimPrefix(r.URL.Path, "/api/items/")

	// Verify ownership
	var budgetUserID string
	err := db.QueryRow("SELECT b.user_id FROM budgets b JOIN category_groups g ON b.id = g.budget_id JOIN category_items i ON g.id = i.group_id WHERE i.id = ?", itemID).Scan(&budgetUserID)
	if err != nil || budgetUserID != userID {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	if r.Method == http.MethodPatch {
		var req CategoryItem
		json.NewDecoder(r.Body).Decode(&req)
		db.Exec("UPDATE category_items SET name = ?, planned_amount = ?, spent_amount = ? WHERE id = ?", req.Name, req.PlannedAmount, req.SpentAmount, itemID)
		w.WriteHeader(http.StatusNoContent)
	} else if r.Method == http.MethodDelete {
		db.Exec("DELETE FROM category_items WHERE id = ?", itemID)
		w.WriteHeader(http.StatusNoContent)
	}
}
