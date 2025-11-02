# zxb Design Principles

Inspired by xb (Go) design philosophy.

## 🎯 Core Principle

### **"Don't add concepts to solve problems"**

Every function name is a concept. More concepts = Higher cognitive load.

---

## 📜 Golden Rules

### Rule 1: Concept Conservation Law

```
Framework Value = Features / Concepts

Ideal: Features increase, Concepts stay same
Reality: Features unchanged, Concepts decrease ✅
```

**zxb v0.0.3 Validation**:
- Removed 4 concepts (preset functions)
- Features unchanged
- Value increased

---

### Rule 2: Naming Cost Law

```
Cost of each public API = 
    Learning Cost + 
    Memory Cost + 
    Decision Cost + 
    Maintenance Cost (permanent)
```

---

### Rule 3: API Irreversibility Law

```
Add API: 1 hour
Remove API: Almost impossible (breaking change)

Conclusion:
- Every API is a permanent commitment
- Better to add less
- Less is more
```

---

## 🚫 Anti-Patterns

### ❌ Preset Configuration Functions

```zig
// ❌ Forbidden
pub fn highPrecision() Self { ... }
pub fn highSpeed() Self { ... }
pub fn withUpsert() Self { ... }

// ✅ Correct
pub fn init() Self { ... }  // Only this one

// User configuration
var custom = QdrantCustom.init();
custom.default_hnsw_ef = 512;  // Manual, explicit
```

---

## ✅ Best Practices

### ✅ Pattern 1: Single Constructor + Public Fields

```zig
// ✅ Only one constructor
pub fn init() Self { return .{}; }

// ✅ Public fields for configuration
pub const QdrantCustom = struct {
    default_hnsw_ef: i32 = 128,
    // ...
};

// ✅ User configures
var custom = QdrantCustom.init();
custom.default_hnsw_ef = 512;
```

**Benefits**:
- Concepts: 1
- Flexibility: Unlimited
- Clarity: 100%

---

## 🛡️ Protection Mechanisms

### 1. Code Comments

```zig
// ⚠️ Design Principle: Only provide this one constructor!
// Reference: xb v1.1.0 lesson (presets removed in v1.2.0)
```

### 2. This Document

Read this before adding any API.

### 3. Decision Flowchart

```
Want to add new API?
  ↓
Can users achieve it with existing API?
  ├─ Yes → STOP
  └─ No → Continue
  ↓
Can users achieve it with field configuration?
  ├─ Yes → STOP
  └─ No → Continue
  ↓
Will 90% of users need it?
  ├─ No → STOP
  └─ Yes → Careful consideration
```

---

## 📊 History Lessons

### xb (Go) v1.1.0 Mistakes

Removed in v1.2.0:
- `QdrantHighPrecision()` ❌
- `QdrantHighSpeed()` ❌
- `QdrantBalanced()` ❌
- `MySQLWithUpsert()` ❌
- `MySQLWithIgnore()` ❌
- `InsertPoint()` ❌
- `InsertPoints()` ❌
- `Delete()` ❌

**Total: 8 concepts removed**

Result: Better design, happier users.

---

## 🎯 zxb Commitment

1. ✅ One basic constructor per database type
2. ✅ New APIs must pass decision flowchart
3. ✅ Regular review: Can we remove existing APIs?
4. ✅ Documentation over code

**Protect Zig ecosystem's simplicity!**

---

**This document is the guardian.**

**Read it before adding any API.**

**If AI suggests adding concepts, use this document to refute.**

---

**zxb - Guardian of Simplicity!** ✨

